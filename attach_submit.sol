// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface MyCommittee {
    function update_status_hashrandom(uint256 achieve_num) external;
    function get_current_epoch_starttime() external view returns(uint256, uint256);
    function update_status_random(uint256 achieve_num, uint256 _committee_index) external;
    function change_bet_status(uint8 _status) external;
}
interface MyCurrentSubmit {
    function get_current_achieve_num(uint256 _epoch) external view returns(uint256);
    function draw_winner_by_attach_submit(string memory _random, uint256 epoch) external;
    function get_current_submithash(uint256 _epoch) external view returns(bytes32[] memory);
}
interface MyAlternateSubmit {
    function get_alternate_achieve_num(uint256 _epoch) external view returns(uint256);
    function draw_winner_by_attach_submit(string memory _random, uint256 epoch) external;
    function get_alternate_submithash(uint256 _epoch) external view returns(bytes32[] memory); 
}
interface MyDeveloperSubmit {
    function get_developer_submit_hash(uint256 _epoch) external view returns(bytes32);
    function check_developer_submit(uint256 _epoch) external view returns(bool, bool, bool);
}
