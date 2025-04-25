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

contract DrawWinner {
    MyCommittee public mycommittee;
    MyCurrentSubmit public mycurrentsubmit;
    MyAlternateSubmit public myalternatesubmit;
    MyHashBall public myHashBall;
    MyPool public mypool;
    // MyEvent public myevent;

    struct EpochMoney{
        uint256 ball_money;
        uint256 committee_money;
        uint256 calculate_accumulative_money;
        uint256 claimed_money;
    }

    struct EpochRewardInfo{
        uint256 epoch;
        uint256[6] epoch_prize1_members;
        uint256 jackpot;
        uint256[3] epoch_prize123_value;
        uint32[6] reward_nums;
    }

    address private owner;  
    bool private initialized; 
    uint256 private total_accumulative_money;
    mapping (uint256 => EpochMoney) private epoch_money;//epoch
    mapping (uint256 => uint32[6]) private epoch_reward_number;//epoch

    mapping (address => bool) private authorize_hashball;//authorize
    mapping (address => bool) private authorize_committee;//authorize
    mapping (address => bool) private authorize_community;//authorize
    mapping (address => bool) private authorize_current_submit;//authorize
    mapping (address => bool) private authorize_alternate_submit;//authorize
    mapping (address => bool) private authorize_developer_submit;//authorize
    mapping (address => bool) private authorize_playball;//authorize


    modifier onlyOwner(){
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyHashBall(){
        require(authorize_hashball[msg.sender], "not authorize");
        _;
    }

    modifier onlyCommittee(){
        require(authorize_committee[msg.sender], "not authorize");
        _;
    }

    modifier onlyCommunity(){
        require(authorize_community[msg.sender], "not authorize");
        _;
    }

    modifier onlyCurrentSubmit(){
        require(authorize_current_submit[msg.sender], "not authorize");
        _;
    }

    modifier onlyAlternateSubmit(){
        require(authorize_alternate_submit[msg.sender], "not authorize");
        _;
    }

    modifier onlyDeveloperSubmit(){
        require(authorize_developer_submit[msg.sender], "not authorize");
        _;
    }

    modifier onlyPlayBall(){
        require(authorize_playball[msg.sender], "not authorize");
        _;
    }

    function initialize(address _owner) public{
        require(!initialized, "already initialized");
        initialized = true;
        owner = _owner;
    }

    function set_mycommittee(address _mycommittee) public onlyOwner{
        mycommittee = MyCommittee(_mycommittee);
    }

    function set_mycurrentsubmit(address _mycurrentsubmit) public onlyOwner{
        mycurrentsubmit = MyCurrentSubmit(_mycurrentsubmit);
    }
    function set_myalternatesubmit(address _myalternatesubmit) public onlyOwner{
        myalternatesubmit = MyAlternateSubmit(_myalternatesubmit);
    }
    function set_hashball(address _myhashball) public onlyOwner{
        myHashBall = MyHashBall(_myhashball);
    }

    function set_mypool(address _mypool) public onlyOwner{
        mypool = MyPool(_mypool);
    }

    function set_authorize_hashball(address _myaddress, bool _true_false) public onlyOwner{
        authorize_hashball[_myaddress] = _true_false;
    }

    function set_authorize_committee(address _myaddress, bool _true_false) public onlyOwner{
        authorize_committee[_myaddress] = _true_false;
    }

    function set_authorize_community(address _myaddress, bool _true_false) public onlyOwner{
        authorize_community[_myaddress] = _true_false;
    }

    function set_authorize_current_submit(address _myaddress, bool _true_false) public onlyOwner{
        authorize_current_submit[_myaddress] = _true_false;
    }

    function set_authorize_alternate_submit(address _myaddress, bool _true_false) public onlyOwner{
        authorize_alternate_submit[_myaddress] = _true_false;
    }

    function set_authorize_developer_submit(address _myaddress, bool _true_false) public onlyOwner{
        authorize_developer_submit[_myaddress] = _true_false;
    }

    function set_authorize_playball(address _myaddress, bool _true_false) public onlyOwner{
        authorize_playball[_myaddress] = _true_false;
    }

    function add_ball_committee_money(uint256 _ball_money, uint256 _committee_value) external onlyPlayBall{
        (uint256 epoch, ) = mycommittee.get_current_epoch_starttime();
        epoch_money[epoch].ball_money += _ball_money;
        epoch_money[epoch].committee_money += _committee_value;
    }

    function add_claimed_money(uint256 _epoch, uint256 _claimed_money) external onlyHashBall{
        epoch_money[_epoch].claimed_money += _claimed_money;
    }

    function add_accumulative_money(uint256 _accumulative_money) external onlyCommunity{
        total_accumulative_money += _accumulative_money;
    }

    function get_epoch_money(uint256 _epoch) public view returns(EpochMoney memory){
        return epoch_money[_epoch];
    }

    function get_total_accumulative_money() public view returns(uint256){
        return total_accumulative_money;
    }

    function set_init_total_accumulative_money(uint256 _init_money) public onlyOwner{
        total_accumulative_money += _init_money;
    }

    function get_epoch_calculate_money(uint256 _epoch) public view returns(uint256){//should current epoch, if not, money not corret
        return (epoch_money[_epoch].ball_money*70/100 + total_accumulative_money*20/100);
    }

    function draw_winner_current_committee(uint256 epoch, bytes32 _newhashrandom, bytes32[10] memory _blockhashs) external onlyCurrentSubmit{
        uint8 bet_status = mycommittee.get_epoch_bet_status(epoch);
        require(bet_status == 8, 'wrong status');
        require(epoch > 0, 'not start');
        
        uint256 k = 0;
        for(uint256 i = 0; i < 6; i++) {
            bytes32 _numhash = keccak256(abi.encodePacked(_newhashrandom, _blockhashs[i], k));
            if(i == 5){
                epoch_reward_number[epoch][i] = uint32(uint256(_numhash) % 26 + 1);
            }else{
                epoch_reward_number[epoch][i] = uint32(uint256(_numhash) % 59 + 1);
            }
            
            for(uint256 j = 0; j < i; j++){
                if(epoch_reward_number[epoch][i] == epoch_reward_number[epoch][j]){
                    i--;
                }
            }
            k +=1;
        }
        sort_num(epoch);

        calculate_prize(epoch);

        // punish_reward_init_committee();
        (uint256 adding_epoch_accumulative_money, uint256 sub_epoch_committee_money ) = mycommittee.punish_reward_init_committee((epoch_money[epoch].committee_money * 30) /1000, epoch_money[epoch].committee_money);
        total_accumulative_money += adding_epoch_accumulative_money;
        if(epoch_money[epoch].committee_money >= sub_epoch_committee_money){
            epoch_money[epoch].committee_money -= sub_epoch_committee_money;
        }
        

        achieve_new_epoch();

    }

    function draw_winner_developer(uint256 epoch, bytes32 _newhashrandom, bytes32 _blockhashs) external onlyDeveloperSubmit{
        uint8 bet_status = mycommittee.get_epoch_bet_status(epoch);
        require(bet_status == 7, 'wrong status');
        require(epoch > 0, 'not start');
        //developer commit
        uint256 k = 0;
        for(uint256 i = 0; i < 6; i++) {
            bytes32 _numhash = keccak256(abi.encodePacked(_newhashrandom, _blockhashs, k));
            if(i == 5){
                epoch_reward_number[epoch][i] = uint32(uint256(_numhash) % 26 + 1);
            }else{
                epoch_reward_number[epoch][i] = uint32(uint256(_numhash) % 59 + 1);
            }
            for(uint256 j = 0; j < i; j++){
                if(epoch_reward_number[epoch][i] == epoch_reward_number[epoch][j]){
                    i--;
                }
            }
            k +=1;
        }
        sort_num(epoch);
        // bet_info[epoch].status = 8;
        mycommittee.change_bet_status(8);

        calculate_prize(epoch);

        // punish_reward_init_committee();
        (uint256 adding_epoch_accumulative_money, uint256 sub_epoch_committee_money ) = mycommittee.punish_reward_init_committee((epoch_money[epoch].committee_money * 30) /1000, epoch_money[epoch].committee_money);
        total_accumulative_money += adding_epoch_accumulative_money;
        if(epoch_money[epoch].committee_money >= sub_epoch_committee_money){
            epoch_money[epoch].committee_money -= sub_epoch_committee_money;
        }

        achieve_new_epoch();
        

    }

    function draw_winner_alternate_committee(uint256 epoch, bytes32 _newhashrandom, bytes32 _blockhashs) external onlyAlternateSubmit{
        uint8 bet_status = mycommittee.get_epoch_bet_status(epoch);
        // require(bet_status == 7, 'wrong status');//need check
        require(bet_status < 7, 'wrong status');
        require(epoch > 0, 'not start');
        //alternate_commit
        uint256 k = 0;
        for(uint256 i = 0; i < 6; i++) {
            bytes32 _numhash = keccak256(abi.encodePacked(_newhashrandom, _blockhashs, k));
            if(i == 5){
                epoch_reward_number[epoch][i] = uint32(uint256(_numhash) % 26 + 1);
            }else{
                epoch_reward_number[epoch][i] = uint32(uint256(_numhash) % 59 + 1);
            }
            for(uint256 j = 0; j < i; j++){
                if(epoch_reward_number[epoch][i] == epoch_reward_number[epoch][j]){
                    i--;
                }
            }
            k +=1;
        }
        sort_num(epoch);
        mycommittee.change_bet_status(8);

        calculate_prize(epoch);

        // punish_reward_init_committee();
        (uint256 adding_epoch_accumulative_money, uint256 sub_epoch_committee_money ) = mycommittee.punish_reward_init_committee((epoch_money[epoch].committee_money * 30) /1000, epoch_money[epoch].committee_money);
        total_accumulative_money += adding_epoch_accumulative_money;
        if(epoch_money[epoch].committee_money >= sub_epoch_committee_money){
            epoch_money[epoch].committee_money -= sub_epoch_committee_money;
        }

        achieve_new_epoch();

    }

    function sort_num(uint256 _epoch) private {
        for (uint256 i = 1; i < 5; i++) {
            uint32 key = epoch_reward_number[_epoch][i];
            uint256 j = i;
            while (j > 0 && epoch_reward_number[_epoch][j-1] > key) {
                // Move the smaller elements
                epoch_reward_number[_epoch][j] = epoch_reward_number[_epoch][j-1];
                j--;
            }
        
            // Place 'key' into its correct location
            epoch_reward_number[_epoch][j] = key;
        }
    }

    function calculate_prize(uint256 _epoch) private{
        //calculate prize
        uint256 _pool_index = (_epoch - 1) % 3;
        uint256 _pool_money = mypool.get_pool_money(_pool_index);
        epoch_money[_epoch].calculate_accumulative_money = total_accumulative_money*20/100;
        uint256 total_value = epoch_money[_epoch].ball_money*70/100 + _pool_money + epoch_money[_epoch].calculate_accumulative_money;
        total_accumulative_money = total_accumulative_money*80/100 + epoch_money[_epoch].ball_money*30/100;

        myHashBall.form_epoch_prize_value(_epoch, total_value);
    }

    function achieve_new_epoch() private{
        uint256 epoch = mycommittee.new_epoch();
        if(epoch > 3){
            uint256 correspond_pool_index = (epoch - 1 - 3) % 3;
            uint256 pool_money = mypool.get_pool_money(correspond_pool_index);
            if((epoch_money[epoch - 3].ball_money*70/100 + pool_money + epoch_money[epoch - 3].calculate_accumulative_money) > epoch_money[epoch - 3].claimed_money){
                uint256 accumulative_money = epoch_money[epoch - 3].ball_money*70/100 + pool_money + epoch_money[epoch - 3].calculate_accumulative_money - epoch_money[epoch - 3].claimed_money;
                if(accumulative_money <= pool_money){
                    mypool.change_pool_money(correspond_pool_index, accumulative_money);

                }else if(accumulative_money > pool_money && accumulative_money > epoch_money[epoch - 3].calculate_accumulative_money + pool_money){
                    uint256 new_accumulative_money = accumulative_money - pool_money - epoch_money[epoch - 3].calculate_accumulative_money;
                    total_accumulative_money += (new_accumulative_money * 80)/100 + epoch_money[epoch - 3].calculate_accumulative_money;
                    mypool.add_pool_money(correspond_pool_index, (new_accumulative_money * 20)/100);
                }else{
                    uint256 new_accumulative_money = accumulative_money - pool_money;
                    total_accumulative_money += new_accumulative_money;
                }
            }
            if(epoch_money[epoch - 3].committee_money > 0){
                epoch_money[epoch].committee_money += epoch_money[epoch - 3].committee_money;
            }
            // bet_info[epoch - 3].status = 9;//end
            // mycommittee.change_bet_status(9);
        }

    }

    function get_epoch_reward_number(uint256 _epoch) external view returns(uint32[6] memory){
        return (epoch_reward_number[_epoch]);
    }

    function get_epoch_reward_info_list(uint256 from, uint256 to) external view returns(EpochRewardInfo[] memory){
        (uint256 epoch, ) = mycommittee.get_current_epoch_starttime();
        require(from > to, 'not allow');
        require(from < epoch, 'from excced');

        EpochRewardInfo[] memory epochrewardinfos = new EpochRewardInfo[](from-to);
        uint256 _index = 0;
        for(uint256 i = from; i > to; i--){
            (uint256[6] memory _epochprizemember, uint256 _jackpot, uint256[3] memory _epochprize123value)= myHashBall.get_prize_member_reward(i);
            epochrewardinfos[_index] = (EpochRewardInfo(i, _epochprizemember, _jackpot, _epochprize123value, epoch_reward_number[i]));
            _index ++;
        }
        return epochrewardinfos;

    }

}
