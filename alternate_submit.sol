// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface MyCommittee {
    function check_current_alternate_commit_hashrandom_changestatus(uint256 _committee_index, address _committee, bool _current) external returns(uint256);
    // function get_current_epoch() external view returns(uint256);
    function get_current_epoch_starttime() external view returns(uint256, uint256);
    function update_status_hashrandom(uint256 achieve_num) external;
    function check_alternate_commit_random(uint256 _committee_index, address _committee) external view returns(uint256, uint256);
    function update_status_random(uint256 achieve_num, uint256 _committee_index) external;
    function change_committee_commit_status(uint8 _status, uint256 _committee_index) external;
    function change_bet_alternate_status(uint8 _status) external;
    function get_epoch_bet_status(uint256 _epoch) external view returns(uint8);
}
interface MyAttachSubmit {
    function check_attach_submit_random(uint256 _epoch) external view returns(bool);
    function get_attach_submit_random(uint256 _epoch) external view returns(string memory);
}
interface MyCurrentSubmit {
    function get_current_achieve_num(uint256 _epoch) external view returns(uint256);
    function get_current_submit_result(uint256 _epoch) external view returns(bytes memory, bytes memory);
}

interface MyDrawWinner {
    function draw_winner_alternate_committee(uint256 epoch, bytes32 _newhashrandom, bytes32 _blockhashs) external;
}
