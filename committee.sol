// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface MyAttachSubmit {
    function check_attach_submit_random(uint256 _epoch) external view returns(bool);
}
interface MyDeveloperSubmit {
    function check_developer_submit_random(uint256 _epoch) external view returns(bool);
}

interface MyPool {
    function get_pool_money(uint256 _index) external view returns(uint256);
}

interface MyDrawWinner {
    function get_epoch_calculate_money(uint256 _epoch) external view returns(uint256);
}

interface MyEvent {
    function emit_committeeearn(address _committee, uint256 _epoch, uint256 _amount, uint256 _time) external;
    function emit_committeepunish(address _committee, uint256 _epoch, uint256 _amount, uint256 _time) external;
}

