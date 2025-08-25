import {RouteProps, Redirect } from "react-router";
import React from "react";
import useSession from 'react-session-hook';


export function PrivateComponent({ children}: RouteProps): any {
    const session = useSession();
    return (
        session.isAuthenticated ? children : <Redirect to={"/login"}/>
    );
}