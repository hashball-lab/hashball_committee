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

contract CurrentSubmit {

    MyCommittee public mycommittee;
    MyAttachSubmit public myattachsubmit;
    MyDrawWinner public mydrawwinner;


    struct CommitInfo{
        bytes32 randomhash;
        bytes32 next_third_block_hash;
        uint256 current_block_num;
        address owner;
        string random;
    }

    mapping (uint256 => CommitInfo[]) private epoch_commit_info;//epoch
    uint256 constant public MAX_COMMIT = 10;
    uint256 constant public BET_DIFF = 60*60*46;
    uint256 constant public COMMIT_DIFF = 60*60*1;
    uint256 constant public VALID_COMMIT = 6;

    address private owner;   
    bool private initialized;
    
    mapping (address => bool) private authorize_attach_submit;//authorize

    modifier onlyOwner(){
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyAttachSubmit(){
        require(authorize_attach_submit[msg.sender], "not authorize");
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

    function set_myattachsubmit(address _myattachsubmit) public onlyOwner{
        myattachsubmit = MyAttachSubmit(_myattachsubmit);
    }
    function set_mydrawwinner(address _mydrawwinner) public onlyOwner{
        mydrawwinner = MyDrawWinner(_mydrawwinner);
    }
    function set_authorize_attach_submit(address _myaddress, bool _true_false) public onlyOwner{
        authorize_attach_submit[_myaddress] = _true_false;
    }

    function commit_hashrandom(bytes32 _hashrandom, uint256 _committee_index) public{//0-99
        uint256 epoch = mycommittee.check_current_alternate_commit_hashrandom_changestatus(_committee_index, msg.sender, true);
        uint256 len = epoch_commit_info[epoch].length;
        require(len <= MAX_COMMIT, 'commit exceed');
        //need to check sender if already commit
        bool has_index = false;
        for(uint256 i =0; i< len && !has_index; i++){
            if(epoch_commit_info[epoch][i].owner == msg.sender){
                epoch_commit_info[epoch][i].randomhash = _hashrandom;
                epoch_commit_info[epoch][i].next_third_block_hash = bytes32(0);
                epoch_commit_info[epoch][i].current_block_num = block.number;
                epoch_commit_info[epoch][i].random = "";
                has_index = true;
            }
        }
        if(!has_index ){
            require(len < MAX_COMMIT, 'commit exceed');
            CommitInfo memory _commitinfo;
            _commitinfo = CommitInfo(_hashrandom, bytes32(0), block.number, msg.sender, "");
            epoch_commit_info[epoch].push(_commitinfo);
        }
    }

    function update_hashrandom_blockhash(uint256 _index, uint256 _committee_index) public{
        (uint256 epoch, ) = mycommittee.get_current_epoch_starttime();
        require(epoch_commit_info[epoch][_index].owner == msg.sender, 'not owner');
        require(epoch_commit_info[epoch][_index].next_third_block_hash == bytes32(0), 'already update blockhash');
        require(epoch_commit_info[epoch][_index].current_block_num  > 0, 'commit hashrandom first');
        require(epoch_commit_info[epoch][_index].current_block_num + 3 + _index < block.number, 'block number not enough');
        require(epoch_commit_info[epoch][_index].current_block_num + 259 + _index > block.number, 'block number exceed');//only get latest 256 block hash
        epoch_commit_info[epoch][_index].next_third_block_hash = blockhash(epoch_commit_info[epoch][_index].current_block_num + 3 + _index);
        mycommittee.change_committee_commit_status(2, _committee_index);
        //check commit random hash valid & commit random hash complete
        uint256 achieve_num = 0;
        for(uint256 i = 0; i < epoch_commit_info[epoch].length; i++) {
            if(epoch_commit_info[epoch][i].next_third_block_hash != bytes32(0)){
                achieve_num += 1;
            }
        }
        if(achieve_num >= VALID_COMMIT && achieve_num < MAX_COMMIT){
            // bet_info[epoch].status = 2;
            mycommittee.change_bet_status(2);
        }else if(achieve_num == MAX_COMMIT){
            // bet_info[epoch].status = 3;
            mycommittee.change_bet_status(3);
        }
              
    }

    function commit_random(string memory _random, uint256 _index, uint256 _committee_index) public{
        (uint256 epoch, uint256 starttime) = mycommittee.check_current_commit_random(_committee_index, msg.sender);
        require(starttime > 0, 'epoch not start');
        require((block.timestamp > (BET_DIFF + starttime + COMMIT_DIFF)) && (block.timestamp < (BET_DIFF + starttime + 2*COMMIT_DIFF)), 'time not allowed');

        require(epoch_commit_info[epoch][_index].next_third_block_hash != bytes32(0), 'bad hashrandom commit');
        require(epoch_commit_info[epoch][_index].owner == msg.sender, 'not owner');
        bytes32 _hashrandom = keccak256(abi.encodePacked(_random));
        require(_hashrandom == epoch_commit_info[epoch][_index].randomhash, 'random invalid');
        require(bytes(epoch_commit_info[epoch][_index].random).length == 0, 'already committed');
        epoch_commit_info[epoch][_index].random = _random;
        mycommittee.change_committee_commit_status(3, _committee_index);
        // check commit random valid & commit random complete
        uint256 achieve_num = 0;
        for(uint256 i = 0; i < epoch_commit_info[epoch].length; i++) {
            if(bytes(epoch_commit_info[epoch][i].random).length != 0){
                achieve_num += 1;
            }
        }
        if(achieve_num >= VALID_COMMIT && achieve_num < MAX_COMMIT){
            mycommittee.change_bet_status(4);
        }else if(achieve_num == MAX_COMMIT){
            if(myattachsubmit.check_attach_submit_random(epoch)){
                mycommittee.change_bet_status(8);
                bytes32[10] memory _blockhashs;
                bytes memory result;
                for(uint256 i = 0; i < epoch_commit_info[epoch].length; i++) {
                    _blockhashs[i] = epoch_commit_info[epoch][i].next_third_block_hash;
                    result = abi.encodePacked(result, epoch_commit_info[epoch][i].random);
                }
                
                result = abi.encodePacked(result, myattachsubmit.get_attach_submit_random(epoch));
                
                bytes32 _newhashrandom = keccak256(abi.encodePacked(result, _blockhashs));
                mydrawwinner.draw_winner_current_committee(epoch, _newhashrandom, _blockhashs);
            }
        }
    }

    function draw_winner_by_attach_submit(string memory _random, uint256 epoch) external onlyAttachSubmit{
        bytes32[10] memory _blockhashs;
        bytes memory result;
        for(uint256 i = 0; i < epoch_commit_info[epoch].length; i++) {
            _blockhashs[i] = epoch_commit_info[epoch][i].next_third_block_hash;
            result = abi.encodePacked(result, epoch_commit_info[epoch][i].random);
        }
        
        result = abi.encodePacked(result, _random);
        
        bytes32 _newhashrandom = keccak256(abi.encodePacked(result, _blockhashs));
        mydrawwinner.draw_winner_current_committee(epoch, _newhashrandom, _blockhashs);
    }

    function get_current_achieve_num(uint256 _epoch) public view returns(uint256){
        uint256 achieve_num = 0;
        for(uint256 i = 0; i < epoch_commit_info[_epoch].length; i++) {
            if(bytes(epoch_commit_info[_epoch][i].random).length != 0){
                achieve_num += 1;
            }
        }
        return achieve_num;
    }

    function get_current_submit_result(uint256 _epoch) external view returns(bytes memory, bytes memory){
        bytes memory result;
        bytes memory _current_blockhash;
        for(uint256 i = 0; i < epoch_commit_info[_epoch].length; i++) {
            if(bytes(epoch_commit_info[_epoch][i].random).length != 0){
                _current_blockhash = abi.encodePacked(_current_blockhash, epoch_commit_info[_epoch][i].next_third_block_hash);
                result = abi.encodePacked(result, epoch_commit_info[_epoch][i].random);
            }
        }
        return (_current_blockhash, result);
    }

    function get_current_submithashrandom_address(uint256 _epoch) external view returns(address[] memory){
        uint256 len = epoch_commit_info[_epoch].length;
        address[] memory addrs = new address[](len);
        for(uint256 i = 0; i < len; i++) {
            addrs[i] = epoch_commit_info[_epoch][i].owner;
        }
        return addrs;
    }

    function get_current_submitrandom_address(uint256 _epoch) external view returns(address[] memory){
        uint256 len = get_current_achieve_num(_epoch);
        address[] memory addrs = new address[](len);
        uint256 _index = 0;
        for(uint256 i = 0; i < epoch_commit_info[_epoch].length; i++) {
            if(bytes(epoch_commit_info[_epoch][i].random).length != 0){
                addrs[_index] = epoch_commit_info[_epoch][i].owner;
                _index ++;
            }
        }
        return addrs;
    }

    function get_current_submit_index(uint256 _epoch, address addr) external view returns(uint256){
        for(uint256 i = 0; i < epoch_commit_info[_epoch].length; i++) {
            if(epoch_commit_info[_epoch][i].owner == addr){
                return i;
            }
        }
        return 10000;
    }

    function get_current_submithash(uint256 _epoch) external view returns(bytes32[] memory){
        uint256 len = epoch_commit_info[_epoch].length;
        bytes32[] memory byts = new bytes32[](len);
        for(uint256 i = 0; i < len; i++) {
            byts[i] = epoch_commit_info[_epoch][i].randomhash;
        }
        return byts;
    }

}
