%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

const DEPLOYER_ADDRESS = 12345678
const NON_DEPLOYER_ADDRESS = 3445223
const NAME = 'Starknet Malaysia'
const SYMBOL = 'Starknet Malaysia'

@view
func __setup__():

    %{ 
        context.contract_address = deploy_contract("./src/attendance_nft.cairo", 
                                                    [ids.NAME, 
                                                    ids.SYMBOL, 
                                                    ids.DEPLOYER_ADDRESS]
                                                ).contract_address 
    %}
    return ()
end

## owner init correct
## token id init correct
## able to pause by owner only
## able to mint when not paused, token id incremented, user balance incremented
## not able to mint when user already has the nft
## not able to mint when paused