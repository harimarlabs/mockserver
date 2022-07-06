import React from "react";
import { Link, useMatch, useNavigate, useLocation, useResolvedPath } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { logoutUser } from "../../store/actions/auth";
import routes from "../../routes/Sidebar";
import SubMenu from "./SubMenu";

const Sidebar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useDispatch();
  // const match = useMatch({ path: resolved.pathname, end: true });
  const logOutHandle = () => {
    dispatch(logoutUser(navigate));
  };

  return (
    <>
      {/* <aside className="main-sidebar sidebar-dark-primary elevation-4">
        <Link to="/profile" className="brand-link">
          <img
            src="https://avatars.githubusercontent.com/u/102525842"
            alt="hugenerd"
            width={30}
            height={30}
            className="rounded-circle"
          />
          <span className="brand-text font-weight-light"> Admin</span>
        </Link>


        <div className="sidebar">
          <nav className="mt-2">
            <ul className="nav nav-pills nav-sidebar flex-column">
              {routes.map((route) =>
                route.routes ? (
                  <SubMenu route={route} key={route.id} />
                ) : (
                  <li
                    className={`${location.pathname === route.path ? "text-white" : ""} nav-item`}
                    key={route.id}
                  >
                    <Link
                      key={route.id}
                      to={route.path}
                      className={`${location.pathname === route.path ? "active" : ""} nav-link `}
                    >
                      {route.name}
                    </Link>
                  </li>
                ),
              )}
            </ul>
          </nav>

          <hr />

          <div className="dropdown pb-4">
            <button type="button" onClick={logOutHandle} className="btn btn-link">
              Sign out
            </button>
          </div>
        </div>
      </aside> */}
      <nav id="sidebar" className="sidebar">
        <div className="sidebar-content">
          <Link className="sidebar-brand" to="/">
            <span className="align-middle">Calyx Care</span>
          </Link>
          <ul className="sidebar-nav">
            {/* <li className="sidebar-header">Pages</li> */}

            {routes.map((route) =>
              route.routes ? (
                <SubMenu route={route} key={route.id} />
              ) : (
                <li
                  className={`${location.pathname === route.path ? "active" : ""} sidebar-item`}
                  key={route.id}
                >
                  <Link
                    key={route.id}
                    to={route.path}
                    className={`${location.pathname === route.path ? "active" : ""} sidebar-link `}
                  >
                    <span className="align-middle">{route.name}</span>
                  </Link>
                </li>
              ),
            )}

            {/* <li className="sidebar-item active">
              <a className="sidebar-link" href="index.html">
                <i className="align-middle" data-feather="sliders" />
                <span className="align-middle">Dashboard</span>
              </a>
            </li> */}

            {/* <li className="sidebar-item">
              <a
                href="/"
                data-bs-target="#dashboards"
                data-bs-toggle="collapse"
                className="sidebar-link collapsed"
                aria-expanded="false"
              >
                <i className="align-middle" data-feather="sliders" />
                <span className="align-middle">Dashboards</span>
              </a>
              <ul
                id="dashboards"
                className="sidebar-dropdown list-unstyled  collapse"
                data-bs-parent="#sidebar"
              >
                <li className="sidebar-item">
                  <a className="sidebar-link" href="index.html">
                    Analytics
                  </a>
                </li>
                <li className="sidebar-item">
                  <a className="sidebar-link" href="dashboard-ecommerce.html">
                    E-Commerce <span className="sidebar-badge badge bg-primary">Pro</span>
                  </a>
                </li>
                <li className="sidebar-item">
                  <a className="sidebar-link" href="dashboard-crypto.html">
                    Crypto <span className="sidebar-badge badge bg-primary">Pro</span>
                  </a>
                </li>
              </ul>
            </li> */}

            {/* <li className="sidebar-item">
              <a className="sidebar-link" href="pages-profile.html">
                <i className="align-middle" data-feather="user" />
                <span className="align-middle">Profile</span>
              </a>
            </li> */}
            {/* <li className="sidebar-item">
              <a className="sidebar-link" href="pages-sign-in.html">
                <i className="align-middle" data-feather="log-in" />
                <span className="align-middle">Sign In</span>
              </a>
            </li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="pages-sign-up.html">
                <i className="align-middle" data-feather="user-plus" />
                <span className="align-middle">Sign Up</span>
              </a>
            </li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="pages-blank.html">
                <i className="align-middle" data-feather="book" />
                <span className="align-middle">Blank</span>
              </a>
            </li>
            <li className="sidebar-header">Tools &amp; Components</li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="ui-buttons.html">
                <i className="align-middle" data-feather="square" />
                <span className="align-middle">Buttons</span>
              </a>
            </li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="ui-forms.html">
                <i className="align-middle" data-feather="check-square" />
                <span className="align-middle">Forms</span>
              </a>
            </li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="ui-cards.html">
                <i className="align-middle" data-feather="grid" />
                <span className="align-middle">Cards</span>
              </a>
            </li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="ui-typography.html">
                <i className="align-middle" data-feather="align-left" />
                <span className="align-middle">Typography</span>
              </a>
            </li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="icons-feather.html">
                <i className="align-middle" data-feather="coffee" />
                <span className="align-middle">Icons</span>
              </a>
            </li>
            <li className="sidebar-header">Plugins &amp; Addons</li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="charts-chartjs.html">
                <i className="align-middle" data-feather="bar-chart-2" />
                <span className="align-middle">Charts</span>
              </a>
            </li>
            <li className="sidebar-item">
              <a className="sidebar-link" href="maps-google.html">
                <i className="align-middle" data-feather="map" />
                <span className="align-middle">Maps</span>
              </a>
            </li> */}
          </ul>
        </div>
      </nav>
    </>
  );
};

export default Sidebar;
