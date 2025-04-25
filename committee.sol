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

contract Committees {

    MyAttachSubmit public myattachsubmit;
    MyDeveloperSubmit public mydevelopersubmit;
    MyPool public mypool;
    MyDrawWinner public mydrawwinner;
    MyEvent public myevent;

    struct BetInfo{
        uint240 start_time;
        uint8 status;
        //1 start, 2 commit random hash valid, 3 commit random hash complete, 4 commit random valid, when commit random complete(start draw)
        //7 Developers submit random hash, 8 complete, 9 end
        uint8 alternate_status;
        //1 start, 2 commit random hash valid, 3 commit random hash complete, 
        //when status is 1 or 2 or 3 or 4, and time is exceed COMMIT_DIFF, then using alternate; once alternate commit random valid, start draw 
        //if still cannot valid, enter developers summit stage
    }
    
    struct CommitteeInfo{
        uint256 committee_index_start;
        uint256 committee_index_end;
        bool _is_committee;
    }

    struct Committee{
        uint256 margin;
        address committee;
        uint48 status;//0 init, 1 enter, 2 in commit, 3 in alternate commit
        uint48 commit_status;//0 init, 1 already hash commited, 2 already update blockhash, 3 already random commited
    }

    uint256 private committee_index_start;
    uint256 private committee_index_end;
    uint256 private epoch;
    address private developer;
    address private third_party;
    address private owner;   
    bool private initialized;
    address private hashball_contract_address; 
    uint256 constant public MAX_COMMIT = 10;
    uint256 constant public MAX_COMMITTEE = 100;
    uint256 constant public Committee_Margin = 1 * (10 ** 17);//price
    uint256 constant public BET_DIFF = 60*60*46;//46 hours
    uint256 constant public COMMIT_DIFF = 60*60*1;
    //committee
    Committee[] private committees;

    mapping (uint256 => BetInfo) private bet_info;//epoch
    mapping (address => bool) private authorize_current_submit;//authorize
    mapping (address => bool) private authorize_alternate_submit;//authorize
    mapping (address => bool) private authorize_draw_winner;//authorize
    mapping (address => bool) private authorize_bet_status;//authorize
    
    mapping (address => bool) private is_committee;//check

    modifier onlyOwner(){
        require(msg.sender == owner, "not owner");
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

    modifier onlyDrawWinner(){
        require(authorize_draw_winner[msg.sender], "not authorize");
        _;
    }

    modifier onlyCurrentSubmit_or_AlternateSubmit(){
        require(authorize_current_submit[msg.sender] || authorize_alternate_submit[msg.sender], "not authorize");
        _;
    }

    modifier onlyBetStatus(){
        require(authorize_bet_status[msg.sender], "not authorize");
        _;
    }

    function initialize(address _developer, address _third_party, address _owner) public{
        require(!initialized, "already initialized");
        initialized = true;
        developer = _developer;
        third_party= _third_party;
        owner = _owner;
        committee_index_start = 0;
        epoch = 1;
    }

    function set_contracts(address _myattachsubmit, address _mydevelopersubmit, address _mypool, address _mydrawwinner, address _myevent) public onlyOwner{
        myattachsubmit = MyAttachSubmit(_myattachsubmit);
        mydevelopersubmit = MyDeveloperSubmit(_mydevelopersubmit);
        mypool = MyPool(_mypool);
        mydrawwinner = MyDrawWinner(_mydrawwinner);
        myevent = MyEvent(_myevent);
    }
    function set_hashball_contract(address _myaddress) public onlyOwner{
        hashball_contract_address = _myaddress;
    }

    function set_authorize_current_submit(address _myaddress, bool _true_false) public onlyOwner{
        authorize_current_submit[_myaddress] = _true_false;
    }

    function set_authorize_alternate_submit(address _myaddress, bool _true_false) public onlyOwner{
        authorize_alternate_submit[_myaddress] = _true_false;
    }

    function set_authorize_draw_winner(address _myaddress, bool _true_false) public onlyOwner{
        authorize_draw_winner[_myaddress] = _true_false;
    }

    function set_authorize_bet_status(address _myaddress, bool _true_false) public onlyOwner{
        authorize_bet_status[_myaddress] = _true_false;
        //attach_submit,current_submit,developer_submit,draw_winner
    }

    receive() external payable {}
    fallback() external payable {}

    function become_committee() public payable{
        if(committees.length < MAX_COMMITTEE){
            require(!is_committee[msg.sender], 'already committee');
            require(msg.value >= Committee_Margin, "not enough pay");
            // if(msg.value > Committee_Margin){
            //     payable (msg.sender).transfer(msg.value - Committee_Margin);
            // }
            committees.push(Committee(Committee_Margin, msg.sender, 1, 0));
            is_committee[msg.sender] = true;
        }else{
            revert('committee index exceed');
        }
    }

    function become_committee_insert(uint256 _index) public payable{
        require(!is_committee[msg.sender], 'already committee');
        require(committees[_index].margin == 0, 'wrong index');
        //if margin is 0, then anyone can become committee
        require(committees[_index].status < 2);
        require(msg.value >= Committee_Margin, "not enough pay");
        // if(msg.value > Committee_Margin){
        //     payable (msg.sender).transfer(msg.value - Committee_Margin);
        // }
        if(committees[_index].committee != address(0)){
            is_committee[committees[_index].committee] = false;
        }
        
        committees[_index].margin = Committee_Margin;
        committees[_index].committee = msg.sender;
        committees[_index].status = 1;
        committees[_index].commit_status = 0;
        is_committee[msg.sender] = true;
    }

    function remove_committee(uint256 _index) public{
        require(committees[_index].committee == msg.sender, 'not committee');
        require(committees[_index].status < 2, 'wrong status');
        uint256 backmoney = committees[_index].margin;
        committees[_index].margin = 0;
        if(backmoney > 0){
            // payable (msg.sender).transfer(committees[_index].margin);
            (bool success, ) = (msg.sender).call{value: backmoney}("");
            if(!success){
                revert('call failed');
            }
        }
        
        committees[_index].committee = address(0);
        committees[_index].status = 0;
        committees[_index].commit_status = 0;
        is_committee[msg.sender] = false;
    }

    function start() public onlyOwner{
        require(epoch == 1 && bet_info[epoch].start_time == 0, 'already started');
        bet_info[epoch].start_time = uint240(block.timestamp);
        bet_info[epoch].status = 1;
        bet_info[epoch].alternate_status = 1;
        require(committees.length >= (2 * MAX_COMMIT), 'insufficient committee');  
        for (uint256 i = 0; i < MAX_COMMIT; i++) {
            if(committee_index_start + i < committees.length){
                committees[committee_index_start + i].status = 2;
                if(committee_index_start + MAX_COMMIT + i < committees.length){
                    committees[committee_index_start + MAX_COMMIT + i].status = 3;
                }else{
                    committees[committee_index_start + MAX_COMMIT + i - committees.length].status = 3;
                }
            }
        }
        committee_index_end = committee_index_start + MAX_COMMIT;
    }

    function check_current_alternate_commit_hashrandom_changestatus(uint256 _committee_index, address _committee, bool _current) external onlyCurrentSubmit_or_AlternateSubmit returns(uint256) {
        require(committees[_committee_index].committee == _committee, 'not committee');
        if(_current){
            require(committees[_committee_index].status == 2, 'not current committee');
        }else{
            require(committees[_committee_index].status == 3, 'not alternate committee');
        }
        
        require(committees[_committee_index].commit_status <= 1, 'already commited');//change, can submit again when not update because chain is congested.
        require(committees[_committee_index].margin >= (Committee_Margin/10), 'not enough margin');//10%
        require(bet_info[epoch].start_time > 0, 'epoch not start');
        require((block.timestamp > (BET_DIFF + bet_info[epoch].start_time)) && (block.timestamp < (BET_DIFF + bet_info[epoch].start_time + COMMIT_DIFF)), 'time not allowed');
        committees[_committee_index].commit_status = 1;//update status
        return epoch;
    }
    function check_current_commit_random(uint256 _committee_index, address _committee) external view returns(uint256, uint256) {
        require(committees[_committee_index].committee == _committee, 'not committee');
        require(committees[_committee_index].status == 2, 'not current committee');
        return (epoch, bet_info[epoch].start_time);
    }

    function check_alternate_commit_random(uint256 _committee_index, address _committee) external view returns(uint256, uint256) {
        require(bet_info[epoch].status < 5, 'status not allowed');
        require(committees[_committee_index].committee == _committee, 'not committee');
        require(committees[_committee_index].status == 3, 'not current committee');
        return (epoch, bet_info[epoch].start_time);
    }
    function change_bet_status(uint8 _status) external onlyBetStatus{
        bet_info[epoch].status = _status;
    }
    function change_bet_alternate_status(uint8 _status) external onlyAlternateSubmit{
        bet_info[epoch].alternate_status = _status;
    }
    function change_committee_commit_status(uint8 _status, uint256 _committee_index) external onlyCurrentSubmit_or_AlternateSubmit{
        committees[_committee_index].commit_status = _status;
    }

    function new_epoch() external onlyDrawWinner returns(uint256){
        //new epoch
        epoch = epoch + 1;
        bet_info[epoch].start_time = uint240(block.timestamp);
        bet_info[epoch].status = 1;
        bet_info[epoch].alternate_status = 1;
        if(epoch > 3){
            bet_info[epoch - 3].status = 9;//end
        }
        return epoch;

    }

    function punish_reward_init_committee(uint256 share_reward, uint256 epoch_committee_money) external onlyDrawWinner returns(uint256, uint256){
        require(committees.length >= (2 * MAX_COMMIT), 'insufficient committee');
        // uint256 share_reward = (epoch_money[epoch].committee_money * 30) /1000; 
        uint256 add_epoch_accumulative_money = 0;
        uint256 sub_epoch_committee_money = 0;
        for(uint256 i = 0; i < committees.length; i++) {
            //orignal status need to init 1
            if(committees[i].status == 2){ //current committee
                if(committees[i].commit_status != 3){//punish
                    if (committees[i].margin > (Committee_Margin/10)){//10%
                        committees[i].margin = committees[i].margin - (Committee_Margin/10);
                        // epoch_money[epoch].accumulative_money += Committee_Margin/5;//give to accumulative
                        myevent.emit_committeepunish(committees[i].committee, epoch, Committee_Margin/10, block.timestamp);
                        add_epoch_accumulative_money += Committee_Margin/10;
                    }else{
                        committees[i].margin = 0;
                    }
                    
                }else{//reward
                    if(epoch_committee_money > (sub_epoch_committee_money + share_reward * 2)){
                        // payable (committees[index_committee + i].committee).transfer(share_reward * 2);
                        (bool success, ) = (committees[i].committee).call{value: share_reward * 2}("");
                        if(!success){
                            revert('call failed');
                        }
                        myevent.emit_committeeearn(committees[i].committee, epoch, share_reward * 2, block.timestamp);
                        // epoch_money[epoch].committee_money -= share_reward * 2;
                        sub_epoch_committee_money += share_reward * 2;
                    }
                }
                committees[i].commit_status = 0;//init
                committees[i].status = 1;//init

            }
            if(committees[i].status == 3){//alternate only reward not punish
                
                if(committees[i].commit_status == 3){
                    if(epoch_committee_money > (sub_epoch_committee_money + share_reward)){
                        // payable (committees[index_committee + MAX_COMMIT + i].committee).transfer(share_reward);
                        (bool success, ) = (committees[i].committee).call{value: share_reward}("");
                        if(!success){
                            revert('call failed');
                        }
                        myevent.emit_committeeearn(committees[i].committee, epoch, share_reward, block.timestamp);
                        // epoch_money[epoch].committee_money -= share_reward;
                        sub_epoch_committee_money += share_reward;
                    }
                }
                committees[i].commit_status = 0;//init
                committees[i].status = 1;//init
            }
            
        }
     
        if(myattachsubmit.check_attach_submit_random(epoch)){
           if(epoch_committee_money > (sub_epoch_committee_money + share_reward * 2)){
                // payable (third_party).transfer(share_reward * 2);
                (bool success, ) = (third_party).call{value: share_reward * 2}("");
                if(!success){
                    revert('call failed');
                }
                myevent.emit_committeeearn(third_party, epoch, share_reward * 2, block.timestamp);
                // epoch_money[epoch].committee_money -= share_reward * 2;
                sub_epoch_committee_money += share_reward * 2;
           }
        }

        // if(bytes(epoch_developer_commit_info[epoch].random).length != 0){//reward developer if achieve developer submit random
        if(mydevelopersubmit.check_developer_submit_random(epoch)){
           if(epoch_committee_money > (sub_epoch_committee_money + share_reward * 2)){
                // payable (developer).transfer(share_reward * 2);
                (bool success, ) = (developer).call{value: share_reward * 2}("");
                if(!success){
                    revert('call failed');
                }
                myevent.emit_committeeearn(developer, epoch, share_reward * 2, block.timestamp);
                // epoch_money[epoch].committee_money -= share_reward * 2;
                sub_epoch_committee_money += share_reward * 2;
           }
        }

        committee_index_start = committee_index_end;
        if(committee_index_end + MAX_COMMIT < committees.length){//0,6,12
            committee_index_end = committee_index_end + MAX_COMMIT;
        }else{
            committee_index_end = committee_index_end + MAX_COMMIT - committees.length;
        } 
        for(uint256 i = 0; i < MAX_COMMIT; i++) {
            committees[(committee_index_start + i) % committees.length].status = 2;
            committees[(committee_index_start + MAX_COMMIT + i) % committees.length].status = 3;
        }
        if(add_epoch_accumulative_money > 0){
            (bool success, ) = (hashball_contract_address).call{value: add_epoch_accumulative_money}("");
            if(!success){
                revert('call failed');
            }
        }

        return(add_epoch_accumulative_money, sub_epoch_committee_money);

    }

    function get_current_epoch_starttime() external view returns(uint256, uint256){
        return (epoch, bet_info[epoch].start_time);
    }

    function get_epoch_bet_status(uint256 _epoch) external view returns(uint8){
        return bet_info[_epoch].status;
    }
    function check_epoch_ball(uint256 _epoch) external view returns(bool){
        if((block.timestamp - bet_info[_epoch].start_time > BET_DIFF) && bet_info[_epoch].status == 8){
            return true;
        }else{
            return false;
        }
    }

    function get_playball_info(address _addr) external view returns(Committee[] memory, CommitteeInfo memory){

        CommitteeInfo memory committeeinfo;
        committeeinfo._is_committee = is_committee[_addr];
        committeeinfo.committee_index_start = committee_index_start;
        committeeinfo.committee_index_end = committee_index_end;
        return (committees, committeeinfo);
        
    }

    function get_info_for_first_page() external view returns(uint256, uint256, uint256){
        uint256 ballmoney = mydrawwinner.get_epoch_calculate_money(epoch);
        uint256 jackpot = ballmoney;
        if(epoch > 0){
            uint256 poolmoney = mypool.get_pool_money((epoch - 1) % 3);
            jackpot += poolmoney;
        }
        return (epoch, bet_info[epoch].start_time, jackpot);

    }
    
}
