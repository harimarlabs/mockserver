// import * as React from "react";
// import { Link } from "react-router-dom";
import { AzureAD, LoginType, AuthenticationState } from "react-aad-msal";

import { useDispatch, useSelector } from "react-redux";
import { authProvider } from "./authProvider";

// import { useNavigate } from 'react-router';
// import { UserContext } from '../../state/UserContext';
// import { useState, useEffect} from 'react';

const AzureADAuth = (props) => {
  // const navigate = useNavigate();
  // const [user, setUser] = useState(null);
  // useEffect ( () => {

  // }, [user]);

  const dispatch = useDispatch();

  return (
    <>
      <AzureAD provider={authProvider}>
        {({ login, logout, authenticationState, error, accountInfo }) => {
          // console.log(authenticationState, accountInfo);

          const isInProgress = authenticationState === AuthenticationState.InProgress;
          const isAuthenticated = authenticationState === AuthenticationState.Authenticated;
          const isUnauthenticated = authenticationState === AuthenticationState.Unauthenticated;

          // console.log(isInProgress, isAuthenticated, isUnauthenticated);

          if (isAuthenticated) {
            // console.log("accountInfo", accountInfo);
            //   // navigate("/roles")
            const userInfo = {
              name: accountInfo.account.name,
              authenticated: true,
              role: "ROLE_CASE_MANAGER,ROLE_ADMIN,ROLE_CARE_MANAGER,ROLE_CARE_GIVER,ROLE_CARE_PHYSICIAN,ROLE_APPLICATION_ADMIN",

              // user: { roles: ["ADMIN"], name: accountInfo.account.name },
              // isAuthenticated: true,
            };

            //         const data = {
            //   accessToken:
            //     "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhZG1pbiIsImlhdCI6MTY1NDA5NTI4OCwiZXhwIjoxNjU0NzAwMDg4fQ.LmYkKVgjOAhjimwAsRbLzkh8NMKKtcDs36HxJd1nUnlnNvd02RXAKDRCZj3uat_YFrxIrwD9fxalyv5t0QDUcw",
            //   tokenType: "Bearer",
            //   firstName: "Admin FName",
            //   userId: 1,
            //   userName: "admin",
            //   roleId: 1,
            //   role: "ROLE_CASE_MANAGER,ROLE_ADMIN,ROLE_CARE_MANAGER,ROLE_CARE_GIVER,ROLE_CARE_PHYSICIAN,ROLE_APPLICATION_ADMIN",
            // };

            return (
              <span>
                {accountInfo && (
                  <>
                    <span style={{ fontWeight: "bold" }}>UserId:</span>{" "}
                    {accountInfo.account.userName}
                    {/* {dispatch({
                      type: "SSO_SUCCESS",
                      payload: [userInfo],
                    })} */}
                    {/* <UserContext.Consumer>
                        {({ signin }) => {
                          if (user == null) {
                            setUser(userInfo);
                            signin(userInfo);
                          }
  
                          return null;
                        }}
                      </UserContext.Consumer> */}
                    <p style={{ padding: 10 }}>Loggedin User:</p>
                    Loggedin User: {accountInfo.account.name}
                  </>
                )}
                &nbsp;
                <button type="button" className="fa fa-sign-out" onClick={logout}>
                  Logout
                </button>
                &nbsp;
                <span style={{ paddingLeft: 15 }}>
                  {/* <Link className="" to="/roles">
                    Continue
                  </Link> */}
                </span>
              </span>
            );
          }

          if (isUnauthenticated || isInProgress) {
            return (
              <button
                className="btn btn-warning float-right"
                type="button"
                onClick={login}
                disabled={isInProgress}
              >
                Sign in using SSO? &nbsp;
                <i className="fa fa-sign-in" />
              </button>
            );
          }
          return true;
        }}
      </AzureAD>
    </>
  );
};

export default AzureADAuth;
