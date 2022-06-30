%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_add
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.security.pausable import Pausable
from openzeppelin.access.ownable import Ownable

@constructor
func constructor{
    syscall_ptr: felt*, 
    range_check_ptr, 
    pedersen_ptr: HashBuiltin*
    }(
        name: felt, 
        symbol: felt,
        owner: felt
    ):
    ERC721.initializer(name, symbol)
    Ownable.initializer(owner)

    # id starts from 1
    current_id.write(Uint256(1,0))
    return ()
end

@storage_var
func current_id() -> (id:Uint256):
end

@storage_var
func user_nft(address: felt) -> (id: Uint256):
end

@storage_var
func ERC721_token_uri(index: felt) -> (res: felt):
end

@storage_var
func ERC721_token_uri_len() -> (res: felt):
end

@view 
func is_paused{
        syscall_ptr: felt*, 
        range_check_ptr, 
        pedersen_ptr: HashBuiltin*
        }() -> (is_paused:felt):
        let (is_paused) = Pausable.is_paused()
        return (is_paused)
end

@view 
func owner{
        syscall_ptr: felt*, 
        range_check_ptr, 
        pedersen_ptr: HashBuiltin*
        }() -> (res: felt):
        let (res) = Ownable.owner()
        return (res)
end

@view
func next_token_id{
        syscall_ptr: felt*, 
        range_check_ptr, 
        pedersen_ptr: HashBuiltin*
        }() -> (id: Uint256):
        let (id) = current_id.read()
        return (id)
end

@view
func name{
        syscall_ptr: felt*, 
        range_check_ptr, 
        pedersen_ptr: HashBuiltin*
        }() -> (name: felt):
        let (name) = ERC721.name()
        return (name)
end

@view 
func balance_of{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(owner: felt) -> (balance: Uint256):
        let (balance) = ERC721.balance_of(owner)
        return (balance)
end

@view
func owner_of{
        syscall_ptr: felt*, 
        range_check_ptr, 
        pedersen_ptr: HashBuiltin*
        }(token_id: Uint256) -> (owner: felt):
        let (owner) = ERC721.owner_of(token_id)
        return (owner)
end

@view
func user_nft_id{
        syscall_ptr: felt*, 
        range_check_ptr, 
        pedersen_ptr: HashBuiltin*
        }(owner: felt) -> (id: Uint256):

        let (id) = user_nft.read(owner)
        return (id)
end

@external
func mint{
        syscall_ptr: felt*, 
        range_check_ptr, 
        pedersen_ptr: HashBuiltin*
        }():
        alloc_locals
        local syscall_ptr_temp: felt*
        assert syscall_ptr_temp = syscall_ptr
        Pausable.assert_not_paused()
        let (addr) = get_caller_address()
        let (balance) = ERC721.balance_of(addr)

        with_attr error_message("User already has minted this NFT"):
            let (is_empty) = uint256_eq(balance, Uint256(0,0))
            assert is_empty = 1
        end

        let (token_id) = current_id.read()
        let (latest_token_id, _) = uint256_add(token_id, Uint256(1,0))
        current_id.write(latest_token_id)
        ERC721._mint(addr, token_id)
        user_nft.write(addr, token_id)

        return ()
end

@external
func pause{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }():
    Ownable.assert_only_owner()
    Pausable._pause()
    return ()
end

@external
func unpause{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }():
    Ownable.assert_only_owner()
    Pausable._unpause()
    return ()
end

@external
func ERC721_Metadata_tokenURI{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*):
        alloc_locals

        let (exists) = ERC721._exists(token_id)
        assert exists = 1

        let (local token_uri) = alloc()
        let (local token_uri_len) = ERC721_token_uri_len.read()

        _ERC721_Metadata_TokenURI(token_uri_len, token_uri)

        return (token_uri_len=token_uri_len, token_uri=token_uri)
end

func _ERC721_Metadata_TokenURI{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(token_uri_len: felt, token_uri: felt*):
        if token_uri_len == 0:
            return ()
        end
        let (token_uri_) = ERC721_token_uri.read(token_uri_len)
        assert [token_uri] = token_uri_
        _ERC721_Metadata_TokenURI(token_uri_len=token_uri_len - 1, token_uri=token_uri + 1)
        return ()
end

@external
func ERC721_Metadata_setTokenURI{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(token_uri_len: felt, token_uri: felt*):
        Ownable.assert_only_owner()
        _ERC721_Metadata_setTokenURI(token_uri_len, token_uri)
        ERC721_token_uri_len.write(token_uri_len)
        return ()
end

func _ERC721_Metadata_setTokenURI{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(token_uri_len: felt, token_uri: felt*):
        if token_uri_len == 0:
            return ()
        end
        ERC721_token_uri.write(index=token_uri_len, value=[token_uri])
        _ERC721_Metadata_setTokenURI(token_uri_len=token_uri_len - 1, token_uri=token_uri + 1)
        return ()
end