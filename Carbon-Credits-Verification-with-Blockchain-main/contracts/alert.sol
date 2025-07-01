// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "Carbon-Credits-Verification-with-Blockchain-main/contracts/lock-contract.sol";


contract AlertMonitor {
    Lock public lock;

    event Message(string);

    VRFD20 public vrf;

    event SendAlert(address addr, string message);

    mapping(address => string) public messages;

    function deployLock() public {
        lock = new Lock();
        lock.deploy();
        lock.isMonitoring(true);
        lock.newProp();
        // lock.addVerifier(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4, true, "testAlert");
        // lock.newProject();
    }

    function getAPI() public {
        vrf = lock.vrf();
    }

    function addVerifier() public {
        lock.addVerifier(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4, true, "testAlert");
    }

    function simulateExistingProject() public {
        lock.newProject();
    }
    
    function returnDeposits() public {
        lock.changeProjectState(lock.getProjectState(4));
    }

    receive() external payable {
        require(address(lock) != address(0), "Lock contract not deployed yet."); 

        (bool success, ) = address(lock).call{value: address(this).balance}(""); 
        require(success, "Failed to send Ether to Lock.");

    }

    function getBalanceLock() public view returns (uint256) {
        return address(lock).balance;
    }

    function getBalanceAlert() public view returns (uint256) {
        return address(this).balance;
    }

    function sendMessage(address recipientAddress) public {
        messages[recipientAddress] = "Your project is scheduled to undergo its annual monitoring.";
        deployLock();
    }

}















    // // string memory message = string.concat("It's time for your monitoring ");
    //         // sendMessage(0xE1B55cE31Bf80BA829c8b4eA219Ad1e80B83b700,message);
    //         deployLock();
    //         //who do I send the second message to? Is it to all the verifiers? Or just to verifiers
        
















contract Recipient {
    string public lastMessage;
    address public sender;

    // Function to receive the message
    function receiveMessage(string calldata message) external {
        lastMessage = message;
        sender = msg.sender; // Stores the sender's address
    }
}

contract SenderMoney {
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


// //contract Sender2 {
// //     // Function to send message to another contract
// //     function sendMessage(address recipientAddress, string memory message) external {
// //         // Interface-style call to the recipient's function
// //         (bool success, ) = recipientAddress.call(
// //             abi.encodeWithSignature("receiveMessage(string)", message)
// //         );
// //         require(success, "Message delivery failed!");
// //     }
// // }