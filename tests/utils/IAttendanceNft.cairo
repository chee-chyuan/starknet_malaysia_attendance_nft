%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAttendanceNft:

    func is_paused() -> (is_paused:felt):
    end

    func owner() -> (res: felt):
    end

    func name() -> (name: felt):
    end

    func balance_of(owner: felt) -> (balance: Uint256):
    end

    func next_token_id() -> (id: Uint256):
    end

    func owner_of(token_id: Uint256) -> (owner: felt):
    end

    func mint():
    end

    func pause():
    end

    func unpause():
    end
end