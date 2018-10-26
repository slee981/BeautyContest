pragma solidity ^0.4.24;

/*
 *  Author... Steven Lee
 *  Email.... steven@booklocal.in
 *  Date..... 10.25.18
 */

import "./BeautyContest.sol";


contract BeatutyContestFactory {

    /********************************************************
     * Storage
     */
    address[] public contests;

    /********************************************************
     * External Functions
     */
    function newBeautyContest(
        uint256 _duration,
        uint256 _cost,
        uint256 _minParticipants,
        uint256 _numeratorForAverage,
        uint256 _divisorForAverage
    )
        external
    {
        address _creator = msg.sender;
        address _contestAddr = new BeatutyContest(
            _duration, _cost, _minParticipants, _numeratorForAverage,
            _divisorForAverage, _creator, address(this));

        contests.push(_contestAddr);
    }

    function endContest(address _contestAddr)
        external
        returns (bool success)
    {
        BeatutyContest _contest = BeatutyContest(_contestAddr);
        success = _contest.endContest();
        _removeContest(_contest);
    }

    function getContests() external view returns (address[]) {
        return contests;
    }

    /********************************************************
     * Internal Functions
     */
    function _removeContest(address _contest)
        internal
    {
        uint256 totalContests = contests.length;
        for (uint256 i=0; i < totalContests; i++) {
            if (contests[i] == _contest) {
                break;
            }
        }

        for (i; i < (totalContests - 1); i++) {
            contests[i] = contests[i+1];
        }
        delete contests[totalContests-1];
        contests.length--;
    }
}
