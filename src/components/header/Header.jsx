import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { Dropdown, DropdownButton } from "react-bootstrap";
import moment from "moment";
import { logoutUser } from "../../store/actions/auth";
import API from "../../util/apiService";

const Header = ({ onToggleSidebar }) => {
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { user } = useSelector((state) => state.auth);
  const [showNotification, setShowNotification] = useState(false);
  const [notificationList, setNotificationList] = useState([]);

  const logout = () => {
    dispatch(logoutUser(navigate));
  };

  const getUsers = () => {
    navigate("/users");
  };

  const handleNotification = () => {
    setShowNotification(!showNotification);
  };

  const fetchNotification = async () => {
    try {
      const { data } = await API.get(`/notification/api/v1/notification/${user.userName}`);
      // console.log("notification", data[0]);
      setNotificationList(data[0]);
    } catch (err) {
      console.log(err);
    }
  };

  useEffect(() => {
    fetchNotification();
  }, []);

  return (
    <>
      <nav className="navbar navbar-expand navbar-light navbar-bg">
        <button type="button" className="btn btn-link shadow-none" onClick={onToggleSidebar}>
          <i className="hamburger align-self-center" />
        </button>

        <div className="navbar-collapse collapse">
          <ul className="navbar-nav navbar-align">
            <li className="nav-item dropdown">
              <button
                type="button"
                className="nav-icon dropdown-toggle bg-white border-0"
                onClick={handleNotification}
              >
                <div className="position-relative">
                  <i className="bi bi-bell sm" />
                  <span className="indicator">{notificationList?.length}</span>
                </div>
              </button>
              <div
                className={`${
                  showNotification ? "show" : ""
                } dropdown-menu dropdown-menu-lg dropdown-menu-end py-0 end-0`}
              >
                <div className="dropdown-menu-header">
                  {notificationList?.length} New Notifications
                </div>
                {/* <div className="list-group">
                  {notificationList &&
                    notificationList.map((item) => (
                      <a
                        href="/notification-detail/restart"
                        className="list-group-item"
                        key={item.createdDate}
                      >
                        <div className="row g-0 align-items-center">
                          <div className="col-2">
                            <i className="text-danger" data-feather="alert-circle" />
                          </div>
                          <div className="col-10">
                            <div className="text-dark">{item.messageType}</div>
                            <div className="text-muted small mt-1">{item.message}</div>
                            <div className="text-muted small mt-1">
                              {moment(item.createdDate).fromNow()}
                            </div>
                          </div>
                        </div>
                      </a>
                    ))}
                </div> */}
                <div className="dropdown-menu-footer">
                  <a href="/notifications" className="text-muted">
                    Show all notifications
                  </a>
                </div>
              </div>
            </li>
            <li className="nav-item dropdown">
              <a className="nav-icon dropdown-toggle" href="/">
                <div className="position-relative">
                  <i className="bi bi-chat-left align-middle" />
                </div>
              </a>
            </li>
            <li className="nav-item dropdown">
              <a className="nav-icon dropdown-toggle" href="/">
                <div className="position-relative">
                  <i className="bi bi-fullscreen" />
                </div>
              </a>
            </li>
            <li className="nav-item dropdown">
              {/* <button type="button" onClick={logout} className="btn btn-link" href="/">
                <span>
                  <i className="bi bi-person-circle" />
                </span>{" "}
                <span className="">{user.name}</span>
              </button> */}

              <Dropdown>
                <Dropdown.Toggle id="dropdown-basic" variant="bg-white">
                  <i className="bi bi-person-circle" /> {user.userName}
                </Dropdown.Toggle>

                <Dropdown.Menu>
                  <Dropdown.Item href="/profile">Profile</Dropdown.Item>
                  <Dropdown.Item href="/dashboard">Settings</Dropdown.Item>
                  <Dropdown.Item>{user?.currentRole}</Dropdown.Item>
                  <Dropdown.Item onClick={getUsers}>UserList</Dropdown.Item>
                  <Dropdown.Item onClick={logout}>Logout</Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>

              {/* <DropdownButton id="dropdown-basic-button" title={user.name}>
                <Dropdown.Item href="#/action-1">Action</Dropdown.Item>
                <Dropdown.Item href="#/action-2">Another action</Dropdown.Item>
                <Dropdown.Item href="#/action-3">Something else</Dropdown.Item>
              </DropdownButton> */}

              {/* <div className="dropdown-menu dropdown-menu-end">
                <a className="dropdown-item" href="pages-profile.html">
                  <i className="align-middle me-1" data-feather="user" />
                  Profile
                </a>
                <a className="dropdown-item" href="/">
                  <i className="align-middle me-1" data-feather="pie-chart" />
                  Analytics
                </a>
                <div className="dropdown-divider" />
                <a className="dropdown-item" href="index.html">
                  <i className="align-middle me-1" data-feather="settings" />
                  Settings &amp; Privacy
                </a>
                <a className="dropdown-item" href="/">
                  <i className="align-middle me-1" data-feather="help-circle" />
                  Help Center
                </a>
                <div className="dropdown-divider" />
                <a className="dropdown-item" href="/">
                  Log out
                </a>
              </div> */}
            </li>
          </ul>
        </div>
      </nav>
    </>
  );
};

export default Header;
