import { Route, RouteProps, Redirect } from "react-router";
import React from "react";
import useSession from 'react-session-hook';


export function PrivateRoute({ children, ...rest }: RouteProps): JSX.Element {

    const session = useSession();
    return (
        <Route
            {...rest}
            render={() =>
                session.isAuthenticated ? (
                    children
                ) : <Redirect to={"/login"}/>
            }
        />
    );
}