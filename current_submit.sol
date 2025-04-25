// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface MyCommittee {
    function check_current_alternate_commit_hashrandom_changestatus(uint256 _committee_index, address _committee, bool _current) external returns(uint256);
    // function get_current_epoch() external view returns(uint256);
    function get_current_epoch_starttime() external view returns(uint256, uint256);
    function change_bet_status(uint8 _status) external;
    function check_current_commit_random(uint256 _committee_index, address _committee) external view returns(uint256, uint256);
    function change_committee_commit_status(uint8 _status, uint256 _committee_index) external;
    function update_status_random(uint256 achieve_num, uint256 _committee_index) external;
}
interface MyAttachSubmit {
    function check_attach_submit_random(uint256 _epoch) external view returns(bool);
    function get_attach_submit_random(uint256 _epoch) external view returns(string memory);
}
interface MyDrawWinner {
    function draw_winner_current_committee(uint256 epoch, bytes32 _newhashrandom, bytes32[10] memory _blockhashs) external;
}
