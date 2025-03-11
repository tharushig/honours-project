// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "Carbon-Credits-Verification-with-Blockchain-main/contracts/carbon.sol";

contract Lock {

    // carbon public carbonContract;
    carbon p;
    
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

    Project public project;
    APIConsumer public apiConsumer;

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

    function getData(uint projectId) public {
        uint data = uint(apiConsumer.requestData(projectId));
        emit Bal(data);
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
        //Need to put the verra address -> perhaps find through chainlink?
        // sendResult(msg.sender, true, true, address(verra));
        // sendResulttest(payable(0x77eC7CE5224728226F56f2b33ac9Aa5D0A368018), true, true);
    }

    //releases deposit based on performance
    function distributePay(Project memory proj, address payable prop) public {
        if (proj.proState == projectState.APPROVED) {
            (uint depProp, uint depVerr) = calculateDeposit(proponents[prop].repScore);
            // paying the proponent
            returnDeposit(proponents[prop].propAddr, depProp);
            
            //paying the verifiers
            returnDeposit(proj.verifyResponse[0].verifier, (depVerr+2000)/3);
            returnDeposit(proj.verifyResponse[1].verifier, (depVerr+2000)/3);
            returnDeposit(proj.verifyResponse[2].verifier, (depVerr+2000)/3);

            //adjusting the reputation score
            proponents[prop].repScore += 1;

            //check that the verifiers have done their job by using oracles
        }
        else if (proj.proState == projectState.REJECTED) {
            // here we want to slash the money

            // adjusting the reputation score
            proponents[prop].repScore -= 1;
        }
        
    }

    //handles payment transfers
    function returnDeposit(address payable addr, uint deposit) public payable {
        (bool sent, bytes memory data) = addr.call{value: deposit}("");
        require(sent, "Failed to send deposit to proponent");
    }
}


contract apiConsumer {
    
}