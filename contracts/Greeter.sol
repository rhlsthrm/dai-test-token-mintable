pragma solidity ^0.6.0;

// Send an 0 value transaction with no data to mint 1,000 new tokens
//
// Symbol      : DAI
// Name        : Dai Stablecoin System
// Total supply: 1,000,000.000000000000000000 + faucet minting
// Decimals    : 18
// Version     : 1
// Chain ID    : 4
// Deployed to : Rinkeby 0x2510f23E0356A38894F39e929002c4fFd23441b3



// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address tokenOwner) public view virtual returns (uint balance);
    function allowance(address tokenOwner, address spender) public view virtual returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract WeenusToken is ERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint _drop;
    address public owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) _allowance;
    mapping (address => uint) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    constructor(string memory symbol_, string memory name_, string memory version_, uint256 chainId_) public {
        decimals = 18;
        _drop = 1000 * 10**uint(decimals);
        symbol = symbol_;
        name = name_;
        owner = msg.sender;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("Dai Semi-Automated Permit Office"),
            keccak256(bytes(version_)),
            chainId_,
            address(this)
        ));
    }
    function totalSupply() public view override returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public override returns (bool success) {
        _allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return _allowance[tokenOwner][spender];
    }

    function mint(address tokenOwner, uint tokens) internal returns (bool success) {
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function drip() public {
        mint(msg.sender, _drop);
    }
    function ownerMint(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        return mint(tokenOwner, tokens);
    }

    receive() external payable {
        mint(msg.sender, _drop);
        if (msg.value > 0) {
            msg.sender.transfer(msg.value);
        }
    }
    
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) public
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));
        require(holder == ecrecover(digest, v, r, s), "invalid permit");
        require(expiry == 0 || now <= expiry, "permit expired");
        require(nonce == nonces[holder]++, "invalid nonce");
        uint wad = allowed ? uint(-1) : 0;
        _allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }

}