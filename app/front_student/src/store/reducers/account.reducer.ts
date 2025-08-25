import { IActionBase } from "../models/root.interface";
import { IAccount } from "../models/account.interface";
import {LOG_IN, LOG_OUT, REGISTER} from "../actions/account.actions";

const initialState: IAccount = {
    email: ""
};

function accountReducer(state: IAccount = initialState, action: IActionBase): IAccount {
    switch (action.type) {
        case LOG_IN: {
            return { ...state, email: (action.email)};
        }
        case LOG_OUT: {
            return { ...state, email: ""};
        }
        case REGISTER: {
            return state;
        }
        default:
            return state;
    }
}


export default accountReducer;