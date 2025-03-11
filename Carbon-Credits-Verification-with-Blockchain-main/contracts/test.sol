// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Test {
    struct Proponents {
        address payable propAddr;
        string name;
        uint256 repScore;
        uint balance;
    }

    event Bal(uint amount);

    mapping (address => Proponents) public proponents;
    
    //handles payment transfers
    function returnDeposit(address payable addr, uint deposit) public payable {
        (bool sent, bytes memory data) = addr.call{value: deposit}("");
        require(sent, "Failed to send deposit to proponent");
    }

    function calculateDeposit(uint256 _repScore) public pure returns(uint,uint) {
        //Let's say fee is $2000
        // Let's make the deposit $1000 (prop deposit + verra deposit)
        // We can say that the total deposit = verra dep + proponent dep + fee paid by prop
        uint propDep = 1000 / (_repScore*5);
        uint verrDep = 1000 - propDep;
        return (propDep,verrDep);
    }
    
    //releases the desosit back to the sender based on results
    //results the state of the project
    function sendResult(address payable proponent, bool valResult, bool verResult, address payable verra) public returns(string memory) {
        (uint depProp, uint depVerr) = calculateDeposit(proponents[proponent].repScore);
        //Proponent documentation result
        if (valResult && verResult) {
            returnDeposit(proponent, depProp);
            returnDeposit(verra, (depVerr + 2000));
            proponents[proponent].repScore += 1;
        }
        else {
            returnDeposit(verra, (depVerr + 2000));
            proponents[proponent].repScore -= 1;
        }
        return "success";
    }

    function sendResulttest(address payable proponent, bool valResult, bool verResult) public returns(string memory) {
        (uint depProp, uint depVerr) = calculateDeposit(proponents[proponent].repScore);
        //Proponent documentation result
        if (valResult && verResult) {
            returnDeposit(proponent, depProp);
            proponents[proponent].repScore += 1;
        }
        else {
            proponents[proponent].repScore -= 1;
        }
        return "success";
    }

}

contract RecievePayment {
    event LogMessage(string message);

    receive() external payable {
        testReturn();
    }

    function testReturn () public {
        emit LogMessage("Test return is executed");
    }

    
}

contract SendValueContract {
    uint256 amount = 1000000000000000000; // 1 ether
    
    receive() external payable {}

    function sendPayment(address payable recipient) public {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Payment failed.");
    }
}


contract Sender {
    function sendEther(address payable receiverAddress) public payable {
        // Sending Ether to the receiver contract
        //Need to do the same for verra but not sure how
        (bool success, ) = receiverAddress.call{value: msg.value}("");
        require(success, "Transfer failed.");
    }
}



//for locking the money
contract testLock {
    //we want to first request a reputation score (for now lets find a fixed thing)
    // then calculate the required deposit amount
    //then send a deposit request (perhaps another function)
    // then we want to get the results of the deposit
    // we needs a trigger that holds the deposit until things are good
    // then once things are good give payments where appropriate
    //if things are back adjust and give payments as required
    // for now let's come up with a reputation-deposit calculation algorithm and ask for a request
    //functions:
    //depositCalculator
    //requestDeposit (should send and request deposit in certain number of days -> perhaps a timestamp?)

    //also should check after each party has deposited -> perhaps a check of the number of receives
    
    struct Proponents {
        string name;
        uint256 repScore;
        uint balance;
    }

    event Bal(uint amount);

    mapping (address => Proponents) public proponents;

    function testSender(address payable proponent) public payable {
        (bool sent, bytes memory data) = proponent.call{value: msg.value}("");
        require(sent, "Failed to send deposit to proponent");
        proponents[msg.sender].repScore += 1;
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

    function getContractBalance(address addr) public view returns (uint) {
        return addr.balance;
    }

    function depositCalculator(uint repScore) pure  public returns (uint256) {
        //project rego fee is $2000 for one methodology and $3000 for multiple methodologies
        // assuming that project only uses the EV one -> $2000
        // thinking of a reputation score from 1-10 since solidity does not support floating point numbers
        require(repScore >=1 && repScore <=10, "Not a valid reputation score");
        uint256 deposit = 2000 / (repScore * 8);
        return deposit;
    }

    function requestDeposit(uint256 depAmount) pure public returns (bool) {
        // we want to use the previous amount calculated and send a request to each party
        // we want to also include the fee in the included amount.
        // so perhaps fee + deposit for the proponent and deposit for Verra
        //placeholder code
        if (depAmount > 0) {
            return true;
        }
        return false;
    }

    

}











// contract Release {
    // function payDeposit (uint256 depAmount, uint256 fee, uint256 repScore, address payable proponet, address payable verra, bool verifiedP, bool verifiedV) public payable {
        //
        // if (verifiedP && verifiedV) {
        //     (bool sent, bytes memory data) = proponet.call{value: depAmount}("");
        //     require(sent, "Failed to send deposit to proponent");
        //     (bool sentV, bytes memory dataV) = verra.call{value: (depAmount+fee)}("");
        //     require(sentV, "Failed to send deposit to verra");
        //     repScore = repScore + 1;
        // }
        // else if (verifiedP && !verifiedV) {
        //     (bool sent, bytes memory data) = proponet.call{value: depAmount}("");
        //     require(sent, "Failed to send deposit to proponent");
        //     (bool sentV, bytes memory dataV) = verra.call{value: fee}("");
        //     require(sentV, "Failed to send deposit to verra");
        //     repScore = repScore + 1;
        // }
        // else if (!verifiedP && verifiedV) {
        //     (bool sentV, bytes memory dataV) = verra.call{value: (depAmount+fee)}("");
        //     require(sentV, "Failed to send deposit to verra");
        //     repScore = repScore - 1;
        // }
        // else {
        //     (bool sentV, bytes memory dataV) = verra.call{value: fee}("");
        //     require(sentV, "Failed to send deposit to verra");
        //     repScore = repScore - 1;
        // }
        // if (repScore == 0) {
        //     repScore = 1;
        // }
        // if (repScore == 11) {
        //     repScore = 10;
        // }
    // }

    
// }