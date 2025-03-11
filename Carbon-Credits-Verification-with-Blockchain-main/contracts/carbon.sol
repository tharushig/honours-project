// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Contract for VRF
contract vrf is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface immutable COORDINATOR;

  uint64 immutable s_subscriptionId;
  bytes32 immutable s_keyHash;
  uint32 constant CALLBACK_GAS_LIMIT = 100000;
  uint16 constant REQUEST_CONFIRMATIONS = 3;
  uint32 constant NUM_WORDS = 2;
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  event ReturnedRandomness(uint256[] randomWords);

  constructor(uint64 subscriptionId, address vrfCoordinator, bytes32 keyHash) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_keyHash = keyHash;
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  function requestRandomWords() external onlyOwner {
    s_requestId = COORDINATOR.requestRandomWords(s_keyHash, s_subscriptionId, REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT, NUM_WORDS);
  }

  function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
    s_randomWords = randomWords;
    emit ReturnedRandomness(randomWords);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}

// Contract for API calls
contract APIConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 public volume;
    bytes32 private jobId;
    uint256 private fee;

    event RequestVolume(bytes32 indexed requestId, uint256 volume);

    constructor() ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        _setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 10;
    }

    function calculateDeposit(uint256 _repScore) public pure returns(uint,uint) {
        //Let's say fee is $2000
        // Let's make the deposit $1000 (prop deposit + verra deposit)
        // We can say that the total deposit = verra dep + proponent dep + fee paid by prop
        uint propDep = 1000 / (_repScore*5);
        uint verrDep = 1000 - propDep;
        return (propDep,verrDep);
    }

    event Data(string);

    function requestData(uint projectId) public returns (bytes32 requestId) {
        emit Data("Executing function");
        Chainlink.Request memory req = _buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        emit Data("Done");
        //use req._add to get rid of this problem
        // req._add("get", string.concat("127.0.0.1:5000/api/data", Strings.toString(projectId)));
        req._add("get", "http://127.0.0.1:5000/data");
        emit Data("Made the get request");
        return _sendChainlinkRequest(req, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, _volume);
        volume = _volume;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))),"Unable to transfer");
    }
}

// Main carbon contract
contract carbon {

  // Struct for Verifiers
  struct Verifier {
    string name;
    string[] methodologies;
  }

  // Struct for project proponents
  struct Proponent {
    address proponent;
    uint projectId;
    Documents docs;
    string name;
    string email;
    string location;
  }

  // Struct for document hash verification
  struct Documents {
    bytes32 docHash;
    bool verified;
  }

  // Struct to represent projects
  struct Project {
    uint projectId;
    address proponent;
    string projectDocs;
    uint startDate;
    uint creditingPeriod;
    string location;
    uint removalGHG;
    string projectType;
    string methodology;
    Response[] validateResponse;
    Response[] verifyResponse;
    projectState proState;
    bool issueCredit;
  }

  // Struct for displaying verification/validation
  struct Response {
    address verifier;
    bool response;
    string reason;
  }

  address public owner;
  address[] public verifierList;
  enum projectState {SUBMITTED, VERIFICATION, VALIDATION, APPROVED, REJECTED}
  uint projectIdCount = 1;
  uint numProponents = 0;
  uint vrfRequest = 1;

  mapping (address => Verifier) public verifiers;
  mapping (address => Proponent) public proponents;
  mapping (uint => Project) public projects;
  mapping (uint => address[]) public projectValidators;
  mapping (uint => address[]) public projectVerifiers;

  vrf public vrfContract;
  APIConsumer public apiConsumer;

  constructor() {
    owner = msg.sender;
  }

  // Function to deploy VRF contract
  function deployVRF(uint64 subscriptionId, address vrfCoordinator, bytes32 keyHash) public {
    vrfContract = new vrf(subscriptionId, vrfCoordinator, keyHash);
  }

  // Function to deploy API contract
  function deployAPI() public {
    apiConsumer = new APIConsumer();
  }

  // Function to post documents hash
  function postDocs(bytes32 docHash) public {
    Proponent storage pr = proponents[msg.sender];
    pr.docs.docHash = docHash;
    pr.docs.verified = false;
  }

  // Function to verify the document hash
  function verifyDocs(address proponent, bool response) public {
    require(msg.sender == owner, "Only owner can verify documents");
    Proponent storage pr = proponents[proponent];
    pr.docs.verified = response;
  }

  // Function to authorise verifiers
  function authoriseVerifiers(address _addr, string memory _name, string memory _methodologies) public returns (uint) {
    require(msg.sender == owner, "Only owner can authorise verifiers");
    Verifier storage v = verifiers[_addr];
    v.name = _name;
    v.methodologies.push(_methodologies);
    verifierList.push(_addr);
    return verifierList.length;
  }

  // Function to remove verifiers
  function removeVerifiers(address addr) public returns (uint) {
    require(msg.sender == owner, "Only owner can remove verifiers");
    delete verifiers[addr];
    for (uint i; i < verifierList.length; i++) {
      if (verifierList[i] == addr) {
        if (i >= verifierList.length) return verifierList.length;
        for (uint j = i; j < verifierList.length - 1; j++) {
           verifierList[i] = verifierList[i+1];
        }
        verifierList.pop();
      }
    }
    return verifierList.length;
  }

  // Function to add methodologies to verifiers
  function addMethodology(address addr, string memory methodology) public {
    require(msg.sender == owner, "Only owner can add methodologies");
    Verifier storage v = verifiers[addr];
    v.methodologies.push(methodology);
  }

  // Function to remove methodologies from verifiers
  function removeMethodology(address addr, string memory methodology) public {
    require(msg.sender == owner, "Only owner can remove methodologies");
    Verifier storage v = verifiers[addr];
    for (uint i; i < v.methodologies.length; i++) {
      if (keccak256(bytes(v.methodologies[i])) == keccak256(bytes(methodology))) {
        delete v.methodologies[i];
      }
    }
  }

  // Function to become proponent
  function addProponent(string memory _name, string memory _email, string memory _location) public returns (uint) {
    Proponent storage pr = proponents[msg.sender];
    pr.name = _name;
    pr.email = _email;
    pr.location = _location;
    numProponents++;
    return numProponents;
  }

  // Function to submit project
  function submitProject(string memory _projectDocs, uint _startDate, uint _creditingPeriod, 
    string memory _location, uint _removalGHG, string memory _projectType, string memory _methodology) public returns (uint) {
      require(bytes(proponents[msg.sender].name).length > 0, "User must make themselves a proponent");
      // require(proponents[msg.sender].docs.verified == true);
      Project storage p = projects[projectIdCount];
      p.proponent = msg.sender;
      p.projectDocs = _projectDocs;
      p.startDate = _startDate;
      p.creditingPeriod = _creditingPeriod;
      p.location = _location;
      p.removalGHG = _removalGHG;
      p.projectType = _projectType;
      p.methodology = _methodology;
      p.proState = projectState.SUBMITTED;
      p.issueCredit = true;

      projectIdCount++;

      Proponent storage pr = proponents[msg.sender];
      pr.projectId = p.projectId;
      return projectIdCount - 1;

  }

  // Function to assign verifiers to project (oracle for random selection)
  function assignVerifiersValidate(uint projectId) public {
    address[] storage x = projectValidators[projectId];
    vrfContract.requestRandomWords();
    uint i = vrfContract.s_randomWords(vrfRequest);
    x.push(verifierList[i % verifierList.length]);
    x.push(verifierList[(i / 2) % verifierList.length]);
    x.push(verifierList[(i * 2) % verifierList.length]);
  }

  // *** TESTING ONLY *** Function to assign verifiers to project (oracle for random selection)
  function assignVerifiersValidateTest(uint projectId) public {
    address[] storage x = projectValidators[projectId];
    x.push(verifierList[0]);
    x.push(verifierList[1]);
    x.push(verifierList[2]);
  }

  // Function to assign verifiers to project (oracle for random selection)
  function assignVerifiersVerify(uint projectId) public {
    address[] storage x = projectVerifiers[projectId];
    vrfContract.requestRandomWords();
    uint i = vrfContract.s_randomWords(vrfRequest);
    x.push(verifierList[i % verifierList.length]);
    x.push(verifierList[(i / 2) % verifierList.length]);
    x.push(verifierList[(i * 2) % verifierList.length]);
  }

    // *** TESTING ONLY *** Function to assign verifiers to project (oracle for random selection)
  function assignVerifiersVerifyTest(uint projectId) public {
    address[] storage x = projectVerifiers[projectId];
    x.push(verifierList[0]);
    x.push(verifierList[1]);
    x.push(verifierList[2]);
  }

  // Function to approve or deny project for validation
  function validateProject(uint projectId, bool response, string memory reason) public returns (uint) {
    require(bytes(verifiers[msg.sender].name).length > 0, "Verifier does not exist");
    require(projects[projectId].proState == projectState.SUBMITTED);
    // require(verifierResponseValidate(msg.sender, projectId), "Verifier already submitted response");
    require(projectValidators[projectId][0] == msg.sender || 
            projectValidators[projectId][1] == msg.sender || 
            projectValidators[projectId][2] == msg.sender, "Verifier not approved for project");
    Response memory r = Response(msg.sender, response, reason);
    Project storage p = projects[projectId];
    p.validateResponse.push(r);

    if (p.validateResponse.length == 3) {
      checkValidate(projectId);
    }
    return p.validateResponse.length;
  }

  // Function to check if verifier has submitted validation response
  function verifierResponseValidate(address addr, uint projectId) public view returns (bool x) {
    Project storage p = projects[projectId];
    for (uint i = 0; i < 3; i++) {
      if (p.validateResponse[i].verifier == addr) {
        return true;
      }
    }
    return false;
  }

  // Function to check the validation results and update the project
  function checkValidate(uint projectId) private {
    Project storage p = projects[projectId];
    if ((p.validateResponse[0].response && p.validateResponse[1].response && p.validateResponse[2].response) || 
          (p.validateResponse[0].response && p.validateResponse[1].response) || 
          (p.validateResponse[1].response && p.validateResponse[2].response) || 
          (p.validateResponse[0].response && p.validateResponse[2].response)) {
        p.proState = projectState.VALIDATION;
      } else {
        p.proState = projectState.REJECTED;
      }
  }

  // Function to approve or deny for verification
  function verifyProject(uint projectId, bool response, string memory reason) public returns (uint) {
    require(bytes(verifiers[msg.sender].name).length > 0, "Verifier does not exist");
    require(projects[projectId].proState == projectState.VALIDATION);
    // require(verifierResponseVerify(msg.sender, projectId), "Verifier already submitted response");
    require(projectVerifiers[projectId][0] == msg.sender || 
            projectVerifiers[projectId][1] == msg.sender || 
            projectVerifiers[projectId][2] == msg.sender, "Verifier not approved for project");
    Response memory r = Response(msg.sender, response, reason);
    Project storage p = projects[projectId];
    p.verifyResponse.push(r);

    if (p.verifyResponse.length == 3) {
      checkVerify(projectId);
    }
    return p.verifyResponse.length;
  }

    // Function to check if verifier has submitted verification response
  function verifierResponseVerify(address addr, uint projectId) public view returns (bool x) {
    Project storage p = projects[projectId];
    // Maybe make a mapping
    for (uint i = 0; i < 3; i++) {
      if (p.verifyResponse[i].verifier == addr) {
        return true;
      }
    }
    return false;
  }

    // Function to check the verifiaction results and update the project
  function checkVerify(uint projectId) private {
    Project storage p = projects[projectId];
    if ((p.verifyResponse[0].response && p.verifyResponse[1].response && p.verifyResponse[2].response) || 
          (p.verifyResponse[0].response && p.verifyResponse[1].response) || 
          (p.verifyResponse[1].response && p.verifyResponse[2].response) || 
          (p.verifyResponse[0].response && p.verifyResponse[2].response)) {
        p.proState = projectState.VERIFICATION;
      } else {
        p.proState = projectState.REJECTED;
      }
  }

  // Get project
  function getProject(uint projectId) public view returns (Project memory) {
    return projects[projectId];
  }

  // Get proponent
  function getProponent(address addr) public view returns (Proponent memory) {
    return proponents[addr];
  }

  // Get verifier
  function getVerifier(address addr) public view returns (string memory) {
    return verifiers[addr].name;
  }


  //### MONITORING FUNCTIONS ###

  // Performs emission calculations on methodology (VM0038)
  function calculateEmissions(uint projectId) public {
    require(msg.sender == owner, "Only owner can calculate emissions");
    Project storage p = projects[projectId];
    uint kWh = uint(apiConsumer.requestData(projectId));
    uint projectEmissions = kWh * 85;
    if (projectEmissions >  p.removalGHG) {
      p.issueCredit = false;
    }
  }

  // *** TESTING ONLY *** Performs emission calculations on methodology (VM0038)
  function calculateEmissionsTest(uint projectId, uint kWh) public {
    Project storage p = projects[projectId];
    uint projectEmissions = kWh * 85;
    if (projectEmissions >  p.removalGHG) {
      p.issueCredit = false;
    }
  }
}