// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

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
        Chainlink.Request memory req = _buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req._add(
            "get",
            "https://0853-14-200-75-54.ngrok-free.app/data"
        );
        req._add("path", "num");
        int256 timesAmount = 10 ** 18;
        req._addInt("times", timesAmount);
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

contract Lock {
    APIConsumer public apiConsumer;
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

    Project public project;
    // APIConsumer public apiConsumer;

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

    event Deposit(string, uint amount);
    event Bal(uint);

    mapping (address => Proponents) public proponents;
    Response[] public validators;
    Response[] public verifiers;

    function getData(uint projectId) public {
        // uint data = uint(apiConsumer.requestData(projectId));
        // emit Bal(data);
    }

    function newProp (string memory _name)  public payable  returns (Proponents memory) {
        Proponents storage pr = proponents[msg.sender];
        pr.name = _name;
        pr.repScore = 10;
        pr.balance = msg.value;
        return pr;
    }

    function getProponent(address addr) public view returns (Proponents memory) {
        return proponents[addr];
    }

    //calculates the deposit based off repScore
    function calculateDeposit(uint256 _repScore) public returns(uint,uint) {
        //Let's say fee is $2000
        // Let's make the deposit $1000 (prop deposit + verra deposit)
        // We can say that the total deposit = verra dep + proponent dep + fee paid by prop
        uint propDep = 1000 / (_repScore*5);
        uint verrDep = 1000 - propDep;
        emit Deposit("The proponent has a deposit to pay of: ", propDep);
        return (propDep,verrDep);
    }

    //Allows the contract recieve payments
    // Has a requirement of having both parties pay their deposit and the fee
    receive() external payable { 
        // require(address(this).balance == 3000, "Not paid");
        uint dataBefore = uint(apiConsumer.requestData(1));
        Response memory resp = Response({verifier : payable(msg.sender), response:true, reason : ""});
        validators.push(resp);
        verifiers.push(resp);
        Project memory p = Project ({
            projectId : 1234567890 , // uint projectId;
            proponent : payable(msg.sender),   //address payable proponent;
            projectDocs: "",          //string memory projectDocs;
            startDate : 1,           //uint startDate;
            creditingPeriod: 5*24*60*60 ,// uint creditingPeriod;
            location:"",             // string memory location;
            removalGHG: 8739.90 * (1 ether),    //uint removalGHG;
            projectType : "",         //string memory projectType;
            methodology:"",         //string memory
            validateResponse: validators,
            verifyResponse: verifiers,
            proState: projectState.SUBMITTED, //projectState proState;
            issueCredit: true
        });

        distributePay(p, p.proponent, dataBefore);
    }
    

    //releases deposit based on performance
    function distributePay(Project memory proj, address payable prop, uint dataBefore) public {
        (uint depProp, uint depVerr) = calculateDeposit(proponents[prop].repScore);
        uint dataAfter = uint(apiConsumer.requestData(1));
        if (proj.proState == projectState.APPROVED) {
            // paying the proponent
            returnDeposit(proponents[prop].propAddr, depProp);

            //adjusting the reputation score
            proponents[prop].repScore += 1;

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
            proponents[prop].repScore -= 1;
        }

        //ensuring repScore remains valid
        checkRepScore(prop);
        
    }

    //handles payment transfers
    function returnDeposit(address payable addr, uint deposit) public payable {
        (bool sent, bytes memory data) = addr.call{value: deposit}("");
        require(sent, "Failed to send deposit to proponent");
    }

    //checks and adjust if repScore is out of bounds
    function checkRepScore (address payable prop) public {
        if (proponents[prop].repScore == 0) {
            proponents[prop].repScore += 1;
        }
        else if (proponents[prop].repScore == 10) {
            proponents[prop].repScore -= 1;
        }
    }
}