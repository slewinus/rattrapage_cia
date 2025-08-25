import { IUser } from "../models/user.interface";
import axios from "axios";
import Cookies from "js-cookie";
export const ADD_ADMIN: string = "ADD_ADMIN";
export const GET_USERS: string = "GET_USERS";
export const REMOVE_ADMIN: string = "REMOVE_ADMIN";

const instance = axios.create({
    baseURL: 'http://' + process.env.REACT_APP_API_URL,
    timeout: 5000,
    headers: {}
});


export function addAdmin(user: IUser): any {
    return async (dispatch : any) => {
        try {
            await instance.patch('/user/' + user.id, {
                username: user.username, role : "ADMIN"
            },{
                headers: {
                    auth: Cookies.get('token')
                }
            });
            return dispatch({ type: ADD_ADMIN, user: user });
        } catch (e) {
            console.log(e);
        }
    }
}

export function removeAdmin(user: IUser): (dispatch: any) => Promise<any> {
    return async (dispatch : any) => {
        try {
            await instance.patch('/user/' + user.id, {
                username: user.username, role : "NORMAL"
            },{
                headers: {
                    auth: Cookies.get('token')
                }
            });
            return dispatch({ type: REMOVE_ADMIN, user: user });
        } catch (e) {
            console.log(e);
        }
    }
}
export function getUsers(): any {

    return async (dispatch : any) => {
        try {
            const response = await instance.get('/user', {
                headers: {
                    auth: Cookies.get('token')
                }
            });
            const tmpUsers : IUser[] = response.data;
            let users : IUser[] = [];
            let admins : IUser[] = [];
            tmpUsers.forEach((user : IUser) => {
                if (user.role === "ADMIN") {
                    admins.push(user);
                }
                else {
                    users.push(user);
                }
            })
            return dispatch({type: GET_USERS, admins, users});
        } catch (e) {
            console.log(e);
        }
    }
}
