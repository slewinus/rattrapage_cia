import { IUserState, IActionBase } from "../models/root.interface";
import {ADD_ADMIN, GET_USERS, REMOVE_ADMIN} from "../actions/users.action";

const initialState: IUserState = {
    users: [
    ],
    admins: [
    ]
};

function userReducer(state: IUserState = initialState, action: IActionBase): IUserState {
    switch (action.type) {
        case ADD_ADMIN: {
            return { ...state, users: state.users.filter(x=>x.id !== action.user.id), admins: [...state.admins, action.user]};
        }
        case REMOVE_ADMIN: {
            return { ...state, admins: state.admins.filter(x=>x.id !== action.user.id), users: [...state.users, action.user]};
        }
        case GET_USERS: {
            return { ...state, users: action.users, admins: action.admins};
        }
        default:
            return state;
    }
}

export default userReducer;