// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


contract RecievePayment {
    event LogMessage(string message);

    receive() external payable {
        testReturn();
    }

    function testReturn () public {
        emit LogMessage("Test return is executed");
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
