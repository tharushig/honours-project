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
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathProjectName", "projectName");
        req._add(
            "urlLocation",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathLocation", "location");
        req._add(
            "urlHash",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathHash", "hash");
        req._add(
            "urlExpectedReductions",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathExpectedReductions", "expectedReductions");
        req._add(
            "urlMethodology",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathMethodology", "methodology");
        req._add(
            "urlProjectStartDate",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathProjectStartDate", "projectStartDate");
        req._add(
            "urlValidationDate",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathValidationDate", "validationDate");
        req._add(
            "urlVerificationDate",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathVerificationDate", "verificationDate");
        req._add(
            "urlIssuedCredits",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
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


/*
Flow Execution:
    - Deploy Lock Contract
    - deploy()
    - Add vrf contract address to vrf subscription manager
    - Deploy sender if not already deployed
    - Send >3000 to lock contract from sender
    - AddVerifier() -> wait until fulfillment is complete on vrf sub manager
    - newProp()
    - newProject()
    - changeProjectState(4)

*/

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
    bool public monitoring;

    VDRSend public vdr;

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
    mapping (address => string) public messages;

    event Deposit(string, uint amount);
    event Balance(string);
    event CheckAddr(address, string);
    event checkResp(Response[], string);

    // Deploys chainlink contracts
    function deploy() public {
        apiConsumer = new APIConsumer();
        vrf = new VRFD20(76195552127779171116519451722131943009323967143011630297663303055390353341770);
        vdr = new VDRSend();
    }

    constructor (bool check) {
        monitoring = check;
    }

    // Adds list of authorised verifiers
    function addVerifier(address verifier, bool resp, string memory message) public {
        Response memory resp0 = Response({verifier : payable (verifier), response:resp, reason : message});
        verifiers.push(resp0);
        Response memory resp1 = Response({verifier : payable (0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), response:false, reason : "number 1"});
        verifiers.push(resp1);
        Response memory resp2 = Response({verifier : payable (0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), response:true, reason : "number 2"});
        verifiers.push(resp2);
        Response memory resp3 = Response({verifier : payable (0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), response:true, reason : "number 3"});
        verifiers.push(resp3);
        Response memory resp4 = Response({verifier : payable (0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), response:false, reason : "number 4"});
        verifiers.push(resp4);
        Response memory resp5 = Response({verifier : payable (0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), response:true, reason : "number 5"});
        verifiers.push(resp5);
        Response memory resp6 = Response({verifier : payable (0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), response:true, reason : "number 6"});
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
    function activateOracle (address opNode) public {
        if (monitoring) {
            messages[msg.sender] = "Your project is scheduled to undergo its annual monitoring.";
            apiConsumer.requestEthereumPrice(opNode, "95edfc2ee2724e1db6db0eecf74d2669");
        }
    }

    // Checks data before and after
    function checkUnchangedData () public {
        if (monitoring == true) {
            dataBefore = apiConsumer.full();
        }
        dataAfter = dataBefore;
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
        p.propAddr = payable(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4);
        p.repScore = 7;
        p.balance= 1;
    }

    // Creates new project
    function newProject() public {
        require(address(apiConsumer) != address(0), "Deploy APIConsumer first!");
        // getNum();
        vrf.s_randomWords(0);
        Project storage p = projects[msg.sender];
    
        p.projectId=6;
        p.proponent=payable(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4);
        p.projectDocs="";
        p.startDate=1;
        p.creditingPeriod=5*24*60*60;
        p.location="Austria";
        p.removalGHG=8739;
        p.projectType="";
        p.methodology="VM003";
        randomiseVerifiers(msg.sender);
        p.proState=projectState.VERIFICATION;
        p.issueCredit=true;
        dataBefore = string(abi.encodePacked("location", "8739", "methodology", "true"));    
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
        // require(address(this).balance >= 3000, "Not enough money distributed");
        (uint depProp, uint depVerr) = calculateDeposit(prop.repScore);
        checkUnchangedData();
        if (proj.proState == projectState.APPROVED) {
            emit Deposit("into approved", 1);
            // paying the proponent
            returnDeposit(prop.propAddr, depProp);

            //adjusting the reputation score
            prop.repScore += 1;
        }
        else if (proj.proState == projectState.REJECTED) {
            // adjusting the reputation score
            prop.repScore -= 1;
        }

        //check that the verifiers have done their job by using oracles
        if (keccak256(abi.encodePacked(dataAfter)) == keccak256(abi.encodePacked(dataBefore))) {
            //paying the verifiers
            returnDeposit(proj.verifyResponse[0].verifier, (depVerr+2000)/3);
            returnDeposit(proj.verifyResponse[1].verifier, (depVerr+2000)/3);
            returnDeposit(proj.verifyResponse[2].verifier, (depVerr+2000)/3);
        }

        //ensuring repScore remains valid
        checkRepScore(prop.propAddr);
        //burn address for the rest of the balance
        returnDeposit(payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), address(this).balance);
        if (monitoring) {
            vdr.submitMonitoring(proj.projectId, proj.methodology, checkVerifiers(), "verifier message");
        }
        else {
            vdr.submitProjectInfo(proj.projectId, "proj", proj.methodology, proj.removalGHG, proj.location, proj.startDate, 21052000, 22052000, 1234923);
        }
        emit Deposit("repScore", prop.balance);
        emit Deposit("msg.sender Balance", msg.sender.balance);
    }

    // Handles payment transfers
    function returnDeposit(address payable addr, uint deposit) public payable {
        (bool sent, bytes memory data) = addr.call{value: deposit}("");
        // require(sent, "Failed to send deposit to proponent");
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



contract VDRSend {
    struct Monitoring {
        uint256 proj_id;
        string methodology;
        bool passed;
        string notes;
    }

    event MonitoringSubmitted(
        uint256 proj_id,
        string methodology,
        bool passed,
        string notes
    );

    struct ProjectInfo {
        uint256 id;
        string name;
        string methodology;
        uint256 expected_reductions;
        string location;
        uint256 start_date;
        uint256 verification_date;
        uint256 validation_date;
        uint256 issued_credits;
    }

    event ProjectInfoSubmitted (
        uint256 id,
        string name,
        string methodology,
        uint256 expected_reductions,
        string location,
        uint256 start_date,
        uint256 verification_date,
        uint256 validation_date,
        uint256 issued_credits
    );

    function submitMonitoring(
        uint256 proj_id,
        string calldata methodology,
        bool passed,
        string calldata notes
    ) public {
        emit MonitoringSubmitted(proj_id, methodology, passed, notes);
    }

    function submitProjectInfo(
        uint256 id,
        string calldata name,
        string calldata methodology,
        uint256 expected_reductions,
        string calldata location,
        uint256 start_date,
        uint256 verification_date,
        uint256 validation_date,
        uint256 issued_credits
    ) public {
        emit ProjectInfoSubmitted (id,name,methodology,expected_reductions,location,start_date,verification_date,validation_date,issued_credits);
    }
}










// function distributePay(address prop) public payable {
    //     require(address(this).balance >= 3000, "Not enough money distributed");
    //     (uint depProp, uint depVerr) = calculateDeposit(proponents[prop].repScore);
    //     checkUnchangedData();
    //     // approved case
    //     if (checkVerifiers()) {
    //         emit Deposit("into approved", 1);
    //         // paying the proponent
    //         returnDeposit(proponents[prop].propAddr, depProp);

    //         //adjusting the reputation score
    //         proponents[prop].repScore += 1;

    //     }
    //     else {
    //         // adjusting the reputation score
    //         proponents[prop].repScore -= 1;
    //     }
        
    //     //check that the verifiers have done their job by using oracles
    //     if (keccak256(abi.encodePacked(dataAfter)) == keccak256(abi.encodePacked(dataBefore))) {
    //         //paying the verifiers
    //         returnDeposit(projects[prop].verifyResponse[0].verifier, (depVerr+2000)/3);
    //         returnDeposit(projects[prop].verifyResponse[1].verifier, (depVerr+2000)/3);
    //         returnDeposit(projects[prop].verifyResponse[2].verifier, (depVerr+2000)/3);
    //     }

    //     //ensuring repScore remains valid
    //     checkRepScore(proponents[prop].propAddr);
    //     //burn address for the rest of the balance
    //     returnDeposit(payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), address(this).balance);
    //     emit Deposit("repScore", prop.balance);
    //     emit Deposit("msg.sender Balance", msg.sender.balance);
    // }