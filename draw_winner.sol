// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface MyCommittee {
    function update_status_hashrandom(uint256 achieve_num) external;
    function get_current_epoch_starttime() external view returns(uint256, uint256);
    function update_status_random(uint256 achieve_num, uint256 _committee_index) external;
    function change_bet_status(uint8 _status) external;
    function get_epoch_bet_status(uint256 _epoch) external view returns(uint8);
    function new_epoch() external returns(uint256);
    function punish_reward_init_committee(uint256 share_reward, uint256 epoch_committee_money) external returns(uint256, uint256);
}
interface MyCurrentSubmit {
    function get_current_achieve_num(uint256 _epoch) external view returns(uint256);
}
interface MyAlternateSubmit {
    function get_alternate_achieve_num(uint256 _epoch) external view returns(uint256);
}
interface MyHashBall {
    function form_epoch_prize_value(uint256 _epoch, uint256 _total_value) external;
    function get_prize_member_reward(uint256 _epoch) external view returns(uint256[6] memory, uint256, uint256[3] memory);
}

interface MyPool {
    function get_pool_money(uint256 _index) external returns(uint256);
    function change_pool_money(uint256 _index, uint256 _money) external;
    function add_pool_money(uint256 _index, uint256 _money) external;
}
