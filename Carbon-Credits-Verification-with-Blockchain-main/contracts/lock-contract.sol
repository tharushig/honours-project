// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//for locking the money
contract Lock {
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
    //

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
        //placeholder code
        if (depAmount > 0) {
            return true;
        }
        return false;
    }

}