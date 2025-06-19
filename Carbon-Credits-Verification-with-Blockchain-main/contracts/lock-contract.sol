// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.4.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.4.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// VRF Contract for randomness
contract VRFD20 is VRFConsumerBaseV2Plus {
    uint256 private constant ROLL_IN_PROGRESS = 42;
    uint256 public s_subscriptionId;
    address public vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 public s_keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint256[] public s_randomWords;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
    }

    function requestRandom() public onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(uint256,uint256[] calldata randomWords ) internal override {
        s_randomWords = randomWords;
    }

}

// API Contract to get data
contract APIConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    string public hash;
    string public full;

    constructor() ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

    function requestEthereumPrice(
        address _oracle,
        string memory _jobId
    ) public onlyOwner {
        Chainlink.Request memory req = _buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillEthereumPrice.selector
        );
        req._add(
            "urlProjectName",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathProjectName", "projectName");
        req._add(
            "urlLocation",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathLocation", "location");
        req._add(
            "urlHash",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathHash", "hash");
        req._add(
            "urlExpectedReductions",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathExpectedReductions", "expectedReductions");
        req._add(
            "urlMethodology",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathMethodology", "methodology");
        req._add(
            "urlProjectStartDate",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathProjectStartDate", "projectStartDate");
        req._add(
            "urlValidationDate",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathValidationDate", "validationDate");
        req._add(
            "urlVerificationDate",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathVerificationDate", "verificationDate");
        req._add(
            "urlIssuedCredits",
            "https://a34b-101-115-19-166.ngrok-free.app/data"
        );
        req._add("pathIssuedCredits", "issuedCredits");
        _sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillEthereumPrice(
        bytes32 _requestId,
        string memory _projectName,
        string memory _location,
        string memory _hash,
        uint256  _expectedReductions,
        string memory _methodology,
        uint256  _projectStartDate,
        uint256  _validationDate,
        uint256  _verificationDate,
        uint256  _issuedCredits
    ) public recordChainlinkFulfillment(_requestId) {
        hash = _hash;
        full = string(abi.encodePacked(_projectName, _location, Strings.toString(_expectedReductions), _methodology));
        full = string(abi.encodePacked(full, Strings.toString(_projectStartDate), Strings.toString(_validationDate), Strings.toString(_verificationDate), Strings.toString(_issuedCredits)));
    }

    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}


// Main Contract
contract Lock {
    struct Project {
        uint projectId;
        address payable proponent;
        string projectDocs;
        uint startDate;
        uint creditingPeriod;
        string location;
        uint removalGHG;
        string projectType;
        string methodology;
        Response[] verifyResponse;
        projectState proState;
        bool issueCredit;
    }

    APIConsumer public apiConsumer;
    VRFD20 public vrf;
    string public dataBefore;
    string public dataAfter;
    uint public vrfNum;
    bool monitoring;

    enum projectState {SUBMITTED, VERIFICATION, VALIDATION, APPROVED, REJECTED}

    struct Response {
        address payable verifier;
        bool response;
        string reason;
    }

    struct Proponents {
        address payable propAddr;
        string name;
        uint256 repScore;
        uint balance;
    }

    Response[] public verifiers;

    mapping (address => Project) public projects;
    mapping (address => Proponents) public proponents;

    event Deposit(string, uint amount);
    event Balance(string);
    event CheckAddr(address, string);
    event checkResp(Response[], string);

    // Deploys chainlink contracts
    function deploy() public {
        apiConsumer = new APIConsumer();
        vrf = new VRFD20(76195552127779171116519451722131943009323967143011630297663303055390353341770);
    }

    // Adds list of authorised verifiers
    function addVerifier(address verifier, bool resp, string memory message) public {
        Response memory resp0 = Response({verifier : payable (verifier), response:resp, reason : message});
        verifiers.push(resp0);
        Response memory resp1 = Response({verifier : payable (0x090fab679bbea10C247209cD6A22A0aC7d9a4829), response:false, reason : "number 1"});
        verifiers.push(resp1);
        Response memory resp2 = Response({verifier : payable (0x84030698cb02D41796503b43a36f61F25422FFF5), response:true, reason : "number 2"});
        verifiers.push(resp2);
        Response memory resp3 = Response({verifier : payable (0x65d24ea35566891CB99ddA55213a4E76c39B806E), response:true, reason : "number 3"});
        verifiers.push(resp3);
        Response memory resp4 = Response({verifier : payable (0x090fab679bbea10C247209cD6A22A0aC7d9a4829), response:false, reason : "number 4"});
        verifiers.push(resp4);
        Response memory resp5 = Response({verifier : payable (0x84030698cb02D41796503b43a36f61F25422FFF5), response:true, reason : "number 5"});
        verifiers.push(resp5);
        Response memory resp6 = Response({verifier : payable (0x65d24ea35566891CB99ddA55213a4E76c39B806E), response:true, reason : "number 6"});
        verifiers.push(resp6);
        vrf.requestRandom();
    }

    // Picks 3 random verifiers
    function randomiseVerifiers(address projectOwner)  public{
        projects[projectOwner].verifyResponse.push(verifiers[vrfNum % verifiers.length]);
        projects[projectOwner].verifyResponse.push(verifiers[(vrfNum / 2) % verifiers.length]);
        projects[projectOwner].verifyResponse.push(verifiers[(vrfNum * 2) % verifiers.length]);
        emit checkResp(projects[msg.sender].verifyResponse, "from project");
    }

    function getVerifiers() view public returns (Response[] memory) {
        return projects[msg.sender].verifyResponse;
    }

    // Gets random value from VRF
    function getNum() public {
        vrfNum = vrf.s_randomWords(0);
    }

    // Checks if lock is deployed during alert contract
    function isMonitoring (bool check) public {
        monitoring = check;
    }

    // Checks data before and after
    function checkUnchangedData (bool time) public {
        if (time == true) {
            if (monitoring == true) {
                dataBefore = apiConsumer.full();
            }
            else {
                dataBefore = "unchanged";
            }
        }
        else {
            if (monitoring == true) {
                dataAfter = apiConsumer.full();
            }
            else {
                dataAfter = "unchanged";
            }
        }
    }

    // Gets the project state value
    function getProjectState(uint val) pure  public  returns (projectState) {
        if (val == 4) {
            return projectState.APPROVED;
        }
        else if (val == 3) {
            return projectState.REJECTED;
        }
        else if (val == 2) {
            return projectState.VALIDATION;
        }
        else if (val == 1) {
            return projectState.VERIFICATION;
        }
        else {
            return projectState.SUBMITTED;
        }

    }

    // Calculates the deposit based off repScore
    function calculateDeposit(uint256 _repScore) public returns(uint,uint) {
        //Let's say fee is $2000
        // Let's make the deposit $1000 (prop deposit + verra deposit)
        uint propDep = 1000 / (_repScore*5);
        uint verrDep = 1000 - propDep;
        emit Deposit("The proponent has to pay a total of: ", propDep+2000);
        emit Deposit("Verra has to pay a total of:", verrDep);
        return (propDep,verrDep);
    }

    // Creates new proponent
    function newProp() public  {
        Proponents storage p = proponents[msg.sender];
        p.name="Sam";
        p.propAddr = payable(0xF3447C8a17761E8E5233fE5a50AC72ceCA387559);
        p.repScore = 7;
        p.balance= 1;
    }

    // Creates new project
    function newProject() public {
        // require(address(apiConsumer) != address(0), "Deploy APIConsumer first!");
        getNum();
        Project storage p = projects[msg.sender];
        p.projectId=1234567890;
        p.proponent=payable(0xF3447C8a17761E8E5233fE5a50AC72ceCA387559);
        p.projectDocs="";
        p.startDate=1;
        p.creditingPeriod=5*24*60*60;
        p.location="";
        p.removalGHG=8739.90 * (1 ether);
        p.projectType="";
        p.methodology="";
        randomiseVerifiers(msg.sender);
        p.proState=projectState.VERIFICATION;
        p.issueCredit=true;
        // uint req = uint(apiConsumer.requestData(1));
    }

   // Checks if verifiers approved the project
   function checkVerifiers () public view returns (bool) {
        uint trueCount = 0;
        for (uint i = 0; i < 3; i ++) 
        {
            if (projects[msg.sender].verifyResponse[i].response) {
                trueCount += 1;
            }
        }
        if (trueCount > 1) {
            return true;
        }
        return false;
   }

    // Simulates the project changing states and executes payment distribution
    function changeProjectState(projectState _proState) public payable  {
        projects[msg.sender].proState = _proState;
        if (_proState == projectState.APPROVED || _proState == projectState.REJECTED) {
            if (address(this).balance >= 3000) {
                if (checkVerifiers() == true) {
                    checkUnchangedData(true);
                    distributePay(projects[msg.sender], proponents[msg.sender]);
                }
                else {
                    emit Balance("Didn't pass validation and verification");
                }
            }
            else {
                emit Balance("Not Enough Deposited");
            }
        }
    }

    //Allows the contract recieve payments
    //Making the assumption that everyone pays deposit at the beginning, before any verification
    receive() external payable { 
        
    }

    // Releases deposit based on performance
    function distributePay(Project memory proj, Proponents memory prop) public payable {
        (uint depProp, uint depVerr) = calculateDeposit(prop.repScore);
        checkUnchangedData(false);
        if (proj.proState == projectState.APPROVED) {
            emit Deposit("into approved", 1);
            // paying the proponent
            returnDeposit(prop.propAddr, depProp);

            //adjusting the reputation score
            prop.repScore += 1;

            //check that the verifiers have done their job by using oracles
            if (keccak256(abi.encodePacked(dataAfter)) == keccak256(abi.encodePacked(dataBefore))) {
                //paying the verifiers
                returnDeposit(proj.verifyResponse[0].verifier, (depVerr+2000)/3);
                returnDeposit(proj.verifyResponse[1].verifier, (depVerr+2000)/3);
                returnDeposit(proj.verifyResponse[2].verifier, (depVerr+2000)/3);
            }
        }
        else if (proj.proState == projectState.REJECTED) {
            //check that the verifiers have done their job by using oracles
            if (keccak256(abi.encodePacked(dataAfter)) == keccak256(abi.encodePacked(dataBefore))) {
                //paying the verifiers
                returnDeposit(proj.verifyResponse[0].verifier, (depVerr+2000)/3);
                returnDeposit(proj.verifyResponse[1].verifier, (depVerr+2000)/3);
                returnDeposit(proj.verifyResponse[2].verifier, (depVerr+2000)/3);
            }
            // adjusting the reputation score
            prop.repScore -= 1;
        }

        //ensuring repScore remains valid
        checkRepScore(prop.propAddr);
        //burn address for the rest of the balance
        returnDeposit(payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), address(this).balance);
        emit Deposit("repScore", prop.balance);
        emit Deposit("msg.sender Balance", msg.sender.balance);
    }

    // Handles payment transfers
    function returnDeposit(address payable addr, uint deposit) public payable {
        (bool sent, bytes memory data) = addr.call{value: deposit}("");
        require(sent, "Failed to send deposit to proponent");
    }

    // Checks and adjusts if repScore is out of bounds
    function checkRepScore (address payable prop) public payable {
        if (proponents[prop].repScore == 0) {
            proponents[prop].repScore += 1;
        }
        else if (proponents[prop].repScore == 10) {
            proponents[prop].repScore -= 1;
        }
    }
}
















contract Sender {
    event LogMessage(string, address);
    function sendEther(address payable receiverAddress) public payable {
        // Sending Ether to the receiver contract
        //Need to do the same for verra but not sure how
        (bool success, ) = receiverAddress.call{value: msg.value}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {
        testReturn();
    }

    function testReturn () public {
        emit LogMessage("Sender received money back", address(this));
    }
}

contract RecievePayment {
    event LogMessage(string message, address addr);

    receive() external payable {
        testReturn();
    }

    function testReturn () public {
        emit LogMessage("Test return is executed", address(this));
    } 
}






// contract APIConsumer is ChainlinkClient, ConfirmedOwner {
//     using Chainlink for Chainlink.Request;

//     uint256 public volume;
//     bytes32 private jobId;
//     uint256 private fee;

//     event RequestVolume(bytes32 indexed requestId, uint256 volume);

//     constructor() ConfirmedOwner(msg.sender) {
//         _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
//         _setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
//         jobId = "ca98366cc7314957b8c012c72f05aeeb";
//         fee = (1 * LINK_DIVISIBILITY) / 10;
//     }

//     event Data(string);
//     event Result(string, uint);

//     function requestData(uint projectId) public returns (bytes32 requestId) {
//         Chainlink.Request memory req = _buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
//         req._add(
//             "get",
//             "https://a34b-101-115-19-166.ngrok-free.app/check"
//         );
//         req._add("path", "num");
//         int256 timesAmount = 1;
//         req._addInt("times", timesAmount);
//         emit Result("Made the get request", projectId);
//         return _sendChainlinkRequest(req, fee);
//     }

//     function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId) {
//         emit RequestVolume(_requestId, _volume);
//         volume = _volume;
//     }

//     function withdrawLink() public onlyOwner {
//         LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
//         require(link.transfer(msg.sender, link.balanceOf(address(this))),"Unable to transfer");
//     }
// }