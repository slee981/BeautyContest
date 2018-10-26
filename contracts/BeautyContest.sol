pragma solidity ^0.4.24;

/*
 *  Author... Steven Lee
 *  Email.... steven@booklocal.in
 *  Date..... 10.25.18
 */

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract BeatutyContest {

    using SafeMath for uint256;

    /********************************************************
     * Storage
     */
    address private contestCreator;
    address public factory;

    mapping (uint256 => address[]) private participantGuesses;
    uint256[] private guesses;
    address[] private participants;

    address[] private winners;
    uint256 private winningGuess;

    uint256 public startTime;
    uint256 public endTime;
    bool public isFinished;

    uint256 public costPerGuess;
    uint256 public minParticipants;

    uint256 public numeratorForAverage;
    uint256 public divisorForAverage;
    uint256 private constant DECIMALS = 18;

    /********************************************************
     * Constructor
     */
    constructor(
        uint256 _duration,
        uint256 _cost,
        uint256 _minParticipants,
        uint256 _numeratorForAverage,
        uint256 _divisorForAverage,
        address _creator,
        address _factory)
        public
    {
        startTime = now;
        endTime = _duration.add(startTime);
        costPerGuess = _cost;
        minParticipants = _minParticipants;
        numeratorForAverage = _numeratorForAverage;
        divisorForAverage = _divisorForAverage;
        contestCreator = _creator;
        factory = _factory;
        isFinished = false;
    }

    /********************************************************
     *  Modifiers
     */
    modifier onlyFactory {
        require(msg.sender == factory);
        _;
    }

    modifier canEnd {
        require(now >= endTime && participants.length >= minParticipants);
        _;
    }

    modifier contestFinished {
        require(isFinished);
        _;
    }

    modifier contestNotFinished {
        require(!isFinished);
        _;
    }

    /********************************************************
     * External Functions
     */
    function endContest()
        external
        onlyFactory
        canEnd
        contestNotFinished
        returns (bool)
    {
        address contestCloser = tx.origin;
        uint256 contractBalance = address(this).balance;

        // internal call sets contract state
        _getWinners();
        uint256 numWinners = winners.length;

        // say creator and closer get 5% each -> 1/20th
        uint256 workerShare = contractBalance.div(20);
        uint256 winnersShare = contractBalance.sub(workerShare.mul(2));

        winnersShare = winnersShare.div(numWinners);

        require(numWinners.mul(winnersShare).add(workerShare).add(workerShare) == contractBalance);

        // transfer
        address _winner;
        for (uint256 i=0; i < numWinners; i++) {
            _winner = winners[i];
            _winner.transfer(winnersShare);
        }
        contestCloser.transfer(workerShare);
        contestCreator.transfer(workerShare);
        return true;
    }

    function guess(uint256 _guess)
        external
        contestNotFinished
        payable
    {
        require(msg.value >= costPerGuess);
        uint256 guessWithDecimals = _guess.mul(10 ** DECIMALS);
        _recordGuess(msg.sender, guessWithDecimals);
    }

    function getWinners()
        external
        view
        contestFinished
        returns (address[])
    {
        return winners;
    }

    function getWinningScore()
        external
        view
        contestFinished
        returns (uint256)
    {
        return winningGuess.div(10**DECIMALS);
    }

    function getCostPerGuess()
        external
        view
        returns (uint256)
    {
        return costPerGuess;
    }

    /********************************************************
     * Public Functions
     */
    function getAllGuesses()
        public
        view
        contestFinished
        returns (uint256[])
    {
        return guesses;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getMinParticipants() public view returns (uint256) {
        return minParticipants;
    }

    /********************************************************
     * Internal Functions
     */
    function _recordGuess(address _participant, uint256 _guess)
        internal
    {
        participantGuesses[_guess].push(_participant);
        guesses.push(_guess);
        participants.push(_participant);
    }

    function _getWinners()
        internal
    {
        uint256 weightedAverage = _getWeightedAverage();

        uint256 _winningGuess = guesses[0];
        uint256 winningDifference = _absDifference(weightedAverage, _winningGuess);
        uint256 totalGuesses = guesses.length;

        uint256 tmpDifference;
        for (uint256 i=0; i < totalGuesses; i++) {
            uint256 _guess = guesses[i];

            tmpDifference = _absDifference(_guess, weightedAverage);

            if (tmpDifference < winningDifference) {
                winningDifference = tmpDifference;
                _winningGuess = _guess;
            }
        }

        winners = participantGuesses[_winningGuess];
        winningGuess = _winningGuess;
        isFinished = true;
    }

    function _getWeightedAverage()
        internal
        view
        returns (uint256)
    {
        uint256 total = 0;
        uint256 totalGuesses = guesses.length;
        for (uint256 i=0; i < totalGuesses; i++) {
            total += guesses[i];
        }
        uint256 average = total.div(totalGuesses);
        return average.div(divisorForAverage).mul(numeratorForAverage);
    }

    function _absDifference(uint256 _n, uint256 _m)
        internal
        pure
        returns (uint256)
    {
        if (_n >= _m) {
            return _n.sub(_m);
        } else {
            return _m.sub(_n);
        }
    }
}
