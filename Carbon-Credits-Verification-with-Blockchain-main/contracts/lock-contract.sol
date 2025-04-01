// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";


// Perhaps the lock contract can be triggered when the proponent submits the project?
// When should the lock contract actually release the pay? Is it when the project passes verification?
// If going by the sequence diagram, then the should be after the verification
// At the moment it is triggered by the balance being enough


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

    event Data(string);
    event Result(string, uint);

    function requestData(uint projectId) public returns (bytes32 requestId) {
        Chainlink.Request memory req = _buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req._add(
            "get",
            "https://0853-14-200-75-54.ngrok-free.app/data"
        );
        req._add("path", "num");
        int256 timesAmount = 1;
        req._addInt("times", timesAmount);
        emit Result("Made the get request", projectId);
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

contract Lock {
    // APIConsumer public apiConsumer;
    // Struct to represent projects
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
        Response[] validateResponse;
        Response[] verifyResponse;
        projectState proState;
        bool issueCredit;
    }

    // Project public project;
    APIConsumer public apiConsumer;
    uint public dataBefore;

    enum projectState {SUBMITTED, VERIFICATION, VALIDATION, APPROVED, REJECTED}

    // Struct for displaying verification/validation
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

    Response[] public validators;
    Response[] public verifiers;
    // Proponents[] public proponents;
    // Project[] public projects;

    mapping (address => Project) public projects;
    mapping (address => Proponents) public proponents;

    event Deposit(string, uint amount);
    event Balance(string);
    event CheckAddr(address, string);

    function deploy() public {
        apiConsumer = new APIConsumer();
    }

    function getProjectState(uint val) pure  public  returns (projectState) {
        if (val == 4) {
            return projectState.APPROVED;
        }
        else if (val == 5) {
            return projectState.REJECTED;
        }
        else if (val == 3) {
            return projectState.VALIDATION;
        }
        else if (val == 2) {
            return projectState.VERIFICATION;
        }
        else {
            return projectState.SUBMITTED;
        }

    }

    //calculates the deposit based off repScore
    function calculateDeposit(uint256 _repScore) public returns(uint,uint) {
        //Let's say fee is $2000
        // Let's make the deposit $1000 (prop deposit + verra deposit)
        uint propDep = 1000 / (_repScore*5);
        uint verrDep = 1000 - propDep;
        emit Deposit("The proponent has to pay a total of: ", propDep+2000);
        emit Deposit("Verra has to pay a total of:", verrDep);
        return (propDep,verrDep);
    }

    function newProject() public {
        require(address(apiConsumer) != address(0), "Deploy APIConsumer first!");
        Response memory resp1 = Response({verifier : payable (0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), response:true, reason : ""});
        validators.push(resp1);
        verifiers.push(resp1);
        Response memory resp2 = Response({verifier : payable (0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), response:true, reason : ""});
        validators.push(resp2);
        verifiers.push(resp2);
        Response memory resp3 = Response({verifier : payable (0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db), response:true, reason : ""});
        validators.push(resp3);
        verifiers.push(resp3);
        Project storage p = projects[msg.sender];
        p.projectId=1234567890;
        p.proponent=payable(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4);
        p.projectDocs="";
        p.startDate=1;
        p.creditingPeriod=5*24*60*60;
        p.location="";
        p.removalGHG=8739.90 * (1 ether);
        p.projectType="";
        p.methodology="";
        p.validateResponse=validators;
        p.verifyResponse=verifiers;
        p.proState=projectState.VERIFICATION;
        p.issueCredit=true;
        uint req = uint(apiConsumer.requestData(1));
    }

    function addProponent() public returns (uint) {
        Proponents storage pr = proponents[msg.sender];
        pr.name = "Sam";
        pr.propAddr = payable(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4);
        pr.repScore = 10;
        pr.balance = 1000000;
        return pr.repScore;
    }

    // simulates the project changing states
    function changeProjectState(projectState _proState) public {
        projects[msg.sender].proState = _proState;
        if (_proState == projectState.APPROVED || _proState == projectState.REJECTED) {
            if (address(this).balance >= 4) {
                dataBefore = apiConsumer.volume();
                uint req = uint(apiConsumer.requestData(1));
                distributePay(projects[msg.sender], proponents[msg.sender]);
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

    //releases deposit based on performance
    function distributePay(Project memory proj, Proponents memory prop) public payable {
        (uint depProp, uint depVerr) = calculateDeposit(prop.repScore);
        // uint dataAfter = 1;
        uint dataAfter = apiConsumer.volume();
        if (proj.proState == projectState.APPROVED) {
            emit Deposit("into approved", 1);
            // paying the proponent
            returnDeposit(payable(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), depProp);

            returnDeposit(proj.verifyResponse[0].verifier, 1);
            returnDeposit(proj.verifyResponse[1].verifier, 1);
            returnDeposit(proj.verifyResponse[2].verifier, 1);

            // //paying the validators
            returnDeposit(proj.validateResponse[0].verifier, 1);
            returnDeposit(proj.validateResponse[1].verifier, 1);
            returnDeposit(proj.validateResponse[2].verifier, 1);

            //adjusting the reputation score
            prop.repScore += 1;

            //check that the verifiers have done their job by using oracles
            if (dataBefore == dataAfter) {
                //paying the verifiers
                returnDeposit(payable(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), depProp);
                returnDeposit(proj.verifyResponse[0].verifier, (depVerr+2000)/3);
                returnDeposit(proj.verifyResponse[1].verifier, (depVerr+2000)/3);
                returnDeposit(proj.verifyResponse[2].verifier, (depVerr+2000)/3);

                // //paying the validators
                returnDeposit(proj.validateResponse[0].verifier, (depVerr+2000)/3);
                returnDeposit(proj.validateResponse[1].verifier, (depVerr+2000)/3);
                returnDeposit(proj.validateResponse[2].verifier, (depVerr+2000)/3);
            }
        }
        else if (proj.proState == projectState.REJECTED) {
            //check that the verifiers have done their job by using oracles
            if (dataBefore == dataAfter) {
                //paying the verifiers
                returnDeposit(proj.verifyResponse[0].verifier, (depVerr+2000)/3);
                returnDeposit(proj.verifyResponse[1].verifier, (depVerr+2000)/3);
                returnDeposit(proj.verifyResponse[2].verifier, (depVerr+2000)/3);

                //paying the validators
                returnDeposit(proj.validateResponse[0].verifier, (depVerr+2000)/3);
                returnDeposit(proj.validateResponse[1].verifier, (depVerr+2000)/3);
                returnDeposit(proj.validateResponse[2].verifier, (depVerr+2000)/3);
            }
            // adjusting the reputation score
            prop.repScore -= 1;
        }

        //ensuring repScore remains valid
        checkRepScore(prop.propAddr);
        //burn address for the rest of the balance
        returnDeposit(payable(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4), address(this).balance);
        emit Deposit("repScore", prop.balance);
        emit Deposit("msg.sender Balance", msg.sender.balance);
    }

    //handles payment transfers
    function returnDeposit(address payable addr, uint deposit) public payable {
        (bool sent, bytes memory data) = addr.call{value: deposit}("");
        require(sent, "Failed to send deposit to proponent");
    }

    //checks and adjust if repScore is out of bounds
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

