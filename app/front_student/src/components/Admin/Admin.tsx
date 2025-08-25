import React, { Fragment } from "react";
import LeftMenu from "../LeftMenu/LeftMenu";
import TopMenu from "../TopMenu/TopMenu";
import { Switch } from "react-router";
import Users from "../Users/Users";
import Home from "../Home/Home";
import Notifications from "../../common/components/Notification";
import {PrivateRoute} from "../../common/components/PrivateRoute";

const Admin: React.FC = () => {

  return (
    <Fragment>
      <Notifications />
      <LeftMenu />
      <div id="content-wrapper" className="d-flex flex-column">
        <div id="content">
          <TopMenu />
          <div className="container-fluid">
            <Switch>
              <PrivateRoute exact path="/users"><Users /></PrivateRoute>
              <PrivateRoute exact path="/"><Home /></PrivateRoute>
            </Switch>
          </div>
        </div>
      </div>
    </Fragment>
  );
};

export default Admin;
