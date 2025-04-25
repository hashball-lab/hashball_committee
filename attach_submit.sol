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

contract AttachSubmit {

    MyCommittee public mycommittee;
    MyCurrentSubmit public mycurrentsubmit;
    MyAlternateSubmit public myalternatesubmit;
    MyDeveloperSubmit public mydevelopersubmit;

    struct CommitInfo{
        bytes32 randomhash;
        bytes32 next_third_block_hash;
        uint256 current_block_num;
        address owner;
        string random;
    }

    struct SubmitInfo{
        bytes32[] current_submit_hash;
        bytes32[] alternate_submit_hash;
        bool attach_submit_hashrandom;
        bool attach_update_blockhash;
        bool attach_submit_random;
        bytes32 attach_submit_hash;
        bool developer_submit_hashrandom;
        bool developer_update_blockhash;
        bool developer_submit_random;
        bytes32 developer_submit_hash;
    }

    mapping (uint256 => CommitInfo) private epoch_attach_commit_info;//epoch
    uint256 constant public MAX_COMMIT = 10;
    uint256 constant public BET_DIFF = 60*60*46;
    uint256 constant public COMMIT_DIFF = 60*60*1;
    uint256 constant public VALID_COMMIT = 6;

    address private owner;   
    address private third_party;
    bool private initialized;

    modifier onlyOwner(){
        require(msg.sender == owner, "not owner");
        _;
    }

    function initialize(address _owner, address _third_party) public{
        require(!initialized, "already initialized");
        initialized = true;
        owner = _owner;
        third_party= _third_party;
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
    function set_mydevelopersubmit(address _mydevelopersubmit) public onlyOwner{
        mydevelopersubmit = MyDeveloperSubmit(_mydevelopersubmit);
    }

    function attach_commit_hashrandom(bytes32 _hashrandom) public{
        require(third_party == msg.sender, 'not third party');
        (uint256 epoch, uint256 starttime) = mycommittee.get_current_epoch_starttime();
        require((block.timestamp > (BET_DIFF + starttime)) && (block.timestamp < (BET_DIFF + starttime + COMMIT_DIFF)), 'time not allowed');
        CommitInfo memory _commitinfo;
        _commitinfo = CommitInfo(_hashrandom, bytes32(0), block.number, msg.sender, "");
        epoch_attach_commit_info[epoch] = _commitinfo;
    }
    function attach_update_hashrandom_blockhash() public{
        (uint256 epoch, ) = mycommittee.get_current_epoch_starttime();
        require(epoch_attach_commit_info[epoch].owner == msg.sender, 'not owner');
        require(epoch_attach_commit_info[epoch].next_third_block_hash == bytes32(0), 'already update blockhash');
        require(epoch_attach_commit_info[epoch].current_block_num  > 0, 'commit hashrandom first');
        require(epoch_attach_commit_info[epoch].current_block_num + 3 < block.number, 'block number not enough');
        require(epoch_attach_commit_info[epoch].current_block_num + 259 > block.number, 'block number exceed');//only get latest 256 block hash
        epoch_attach_commit_info[epoch].next_third_block_hash = blockhash(epoch_attach_commit_info[epoch].current_block_num + 3);
    }
    function attach_commit_random(string memory _random) public{
        (uint256 epoch, uint256 starttime) = mycommittee.get_current_epoch_starttime();
        require(starttime > 0, 'epoch not start');
        require((block.timestamp > (BET_DIFF + starttime + COMMIT_DIFF)) && (block.timestamp < (BET_DIFF + starttime + 2*COMMIT_DIFF)), 'time not allowed');
        // require(block.timestamp - starttime > BET_DIFF, 'time not allowed');
        // require((block.timestamp - starttime) < (BET_DIFF + COMMIT_DIFF*2), 'time exceed');
        require(epoch_attach_commit_info[epoch].next_third_block_hash != bytes32(0), 'bad hashrandom commit');
        require(epoch_attach_commit_info[epoch].owner == msg.sender, 'not owner');
        bytes32 _hashrandom = keccak256(abi.encodePacked(_random));
        require(_hashrandom == epoch_attach_commit_info[epoch].randomhash, 'random invalid');
        require(bytes(epoch_attach_commit_info[epoch].random).length == 0, 'already committed');
        epoch_attach_commit_info[epoch].random = _random;
        // check commit random valid & commit random complete
        if((block.timestamp - starttime) <= (BET_DIFF + 2* COMMIT_DIFF)){
            uint256 achieve_num = mycurrentsubmit.get_current_achieve_num(epoch);
            if(achieve_num == MAX_COMMIT){
                mycommittee.change_bet_status(8);
                mycurrentsubmit.draw_winner_by_attach_submit(_random, epoch);
            }
        }else{
            uint256 achieve_num1 = mycurrentsubmit.get_current_achieve_num(epoch);
            uint256 achieve_num2 = myalternatesubmit.get_alternate_achieve_num(epoch); 
            if((achieve_num1 + achieve_num2) >= VALID_COMMIT){
                myalternatesubmit.draw_winner_by_attach_submit(_random, epoch);
            }
        }
       
    }
    
    function check_attach_submit(uint256 _epoch) public view returns(bool, bool, bool){
        bool _submit_hashrandom;
        bool _update_blockhash;
        bool _submit_random;

        if(epoch_attach_commit_info[_epoch].randomhash != bytes32(0)){
            _submit_hashrandom = true;
        }
        if(epoch_attach_commit_info[_epoch].next_third_block_hash != bytes32(0)){
            _update_blockhash = true;
        }
        if(bytes(epoch_attach_commit_info[_epoch].random).length != 0){
            _submit_random = true;
        }
        return (_submit_hashrandom, _update_blockhash, _submit_random);
    }
    function check_attach_submit_random(uint256 _epoch) external view returns(bool){
        if(bytes(epoch_attach_commit_info[_epoch].random).length != 0){
            return true;
        }else{
            return false;
        }
    }
    function get_attach_submit_random(uint256 _epoch) external view returns(string memory){
        return epoch_attach_commit_info[_epoch].random;
    }
    function get_attach_submit_hash(uint256 _epoch) external view returns(bytes32){
        return epoch_attach_commit_info[_epoch].randomhash;
    }

    function get_submit_info(uint256 epoch) external view returns(SubmitInfo memory){

        SubmitInfo memory submitinfo;
        submitinfo.current_submit_hash = mycurrentsubmit.get_current_submithash(epoch);
        submitinfo.alternate_submit_hash = myalternatesubmit.get_alternate_submithash(epoch);

        (bool _attach_submit_hashrandom, bool _attach_update_blockhash, bool _attach_submit_random) = check_attach_submit(epoch);
        (bool _developer_submit_hashrandom, bool _developer_update_blockhash, bool _developer_submit_random) = mydevelopersubmit.check_developer_submit(epoch);
        submitinfo.attach_submit_hashrandom = _attach_submit_hashrandom;
        submitinfo.attach_update_blockhash = _attach_update_blockhash;
        submitinfo.attach_submit_random = _attach_submit_random;
        submitinfo.developer_submit_hashrandom = _developer_submit_hashrandom;
        submitinfo.developer_update_blockhash = _developer_update_blockhash;
        submitinfo.developer_submit_random = _developer_submit_random;
        submitinfo.attach_submit_hash = epoch_attach_commit_info[epoch].randomhash;
        submitinfo.developer_submit_hash = mydevelopersubmit.get_developer_submit_hash(epoch);

        return submitinfo;

    }
}
