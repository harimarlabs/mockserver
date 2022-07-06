import React from "react";
import { Link } from "react-router-dom";

const NotFound = () => {
  return (
    <div className="wrapper">
      <nav id="sidebar" className="sidebar">
        <div className="sidebar-content">
          <a className="sidebar-brand" href="index.html">
            <span className="align-middle">AdminKit</span>
          </a>
          <ul className="sidebar-nav">
            <li className="sidebar-header">Pages</li>
            <li className="sidebar-item active">
              <a className="sidebar-link" href="index.html">
                <i className="align-middle" data-feather="sliders" />
                <span className="align-middle">Dashboard</span>
              </a>
            </li>

            <li className="sidebar-item">
              <a
                href="/"
                data-bs-target="#dashboards"
                data-bs-toggle="collapse"
                className="sidebar-link collapsed"
                aria-expanded="false"
              >
                <span className="align-middle">Dashboards</span>
              </a>
              <ul
                id="dashboards"
                className="sidebar-dropdown list-unstyled collapse "
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
            </li>

            <li className="sidebar-item">
              <a className="sidebar-link" href="pages-profile.html">
                <i className="align-middle" data-feather="user" />
                <span className="align-middle">Profile</span>
              </a>
            </li>
            <li className="sidebar-item">
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
            </li>
          </ul>
          <div className="sidebar-cta">
            <div className="sidebar-cta-content">
              <strong className="d-inline-block mb-2">Upgrade to Pro</strong>
              <div className="mb-3 text-sm">
                Are you looking for more components? Check out our premium version.
              </div>
              <div className="d-grid">
                <a href="upgrade-to-pro.html" className="btn btn-primary">
                  Upgrade to Pro
                </a>
              </div>
            </div>
          </div>
        </div>
      </nav>

      <div className="main">
        <nav className="navbar navbar-expand navbar-light navbar-bg">
          <a href="/" className="sidebar-toggle js-sidebar-toggle">
            <i className="hamburger align-self-center" />
          </a>
          <div className="navbar-collapse collapse">
            <ul className="navbar-nav navbar-align">
              <li className="nav-item dropdown">
                <a
                  className="nav-icon dropdown-toggle"
                  href="/"
                  id="alertsDropdown"
                  data-bs-toggle="dropdown"
                >
                  <div className="position-relative">
                    <i className="bi bi-bell sm" />
                    <span className="indicator">4</span>
                  </div>
                </a>
                <div
                  className="dropdown-menu dropdown-menu-lg dropdown-menu-end py-0"
                  aria-labelledby="alertsDropdown"
                >
                  <div className="dropdown-menu-header">4 New Notifications</div>
                  <div className="list-group">
                    <a href="/" className="list-group-item">
                      <div className="row g-0 align-items-center">
                        <div className="col-2">
                          <i className="text-danger" data-feather="alert-circle" />
                        </div>
                        <div className="col-10">
                          <div className="text-dark">Update completed</div>
                          <div className="text-muted small mt-1">
                            Restart server 12 to complete the update.
                          </div>
                          <div className="text-muted small mt-1">30m ago</div>
                        </div>
                      </div>
                    </a>
                    <a href="/" className="list-group-item">
                      <div className="row g-0 align-items-center">
                        <div className="col-2">
                          <i className="text-warning" data-feather="bell" />
                        </div>
                        <div className="col-10">
                          <div className="text-dark">Lorem ipsum</div>
                          <div className="text-muted small mt-1">
                            Aliquam ex eros, imperdiet vulputate hendrerit et.
                          </div>
                          <div className="text-muted small mt-1">2h ago</div>
                        </div>
                      </div>
                    </a>
                    <a href="/" className="list-group-item">
                      <div className="row g-0 align-items-center">
                        <div className="col-2">
                          <i className="text-primary" data-feather="home" />
                        </div>
                        <div className="col-10">
                          <div className="text-dark">Login from 192.186.1.8</div>
                          <div className="text-muted small mt-1">5h ago</div>
                        </div>
                      </div>
                    </a>
                    <a href="/" className="list-group-item">
                      <div className="row g-0 align-items-center">
                        <div className="col-2">
                          <i className="text-success" data-feather="user-plus" />
                        </div>
                        <div className="col-10">
                          <div className="text-dark">New connection</div>
                          <div className="text-muted small mt-1">
                            Christina accepted your request.
                          </div>
                          <div className="text-muted small mt-1">14h ago</div>
                        </div>
                      </div>
                    </a>
                  </div>
                  <div className="dropdown-menu-footer">
                    <a href="/" className="text-muted">
                      Show all notifications
                    </a>
                  </div>
                </div>
              </li>
              <li className="nav-item dropdown">
                <a
                  className="nav-icon dropdown-toggle"
                  href="/"
                  id="messagesDropdown"
                  data-bs-toggle="dropdown"
                >
                  <div className="position-relative">
                    {/* <i className="align-middle" data-feather="message-square" /> */}
                    <i className="bi bi-chat-left align-middle" />
                  </div>
                </a>
                <div
                  className="dropdown-menu dropdown-menu-lg dropdown-menu-end py-0"
                  aria-labelledby="messagesDropdown"
                >
                  <div className="dropdown-menu-header">
                    <div className="position-relative">4 New Messages</div>
                  </div>
                  <div className="list-group">
                    <a href="/" className="list-group-item">
                      <div className="row g-0 align-items-center">
                        <div className="col-2">
                          <img
                            src="img/avatars/avatar-5.jpg"
                            className="avatar img-fluid rounded-circle"
                            alt="Vanessa Tucker"
                          />
                        </div>
                        <div className="col-10 ps-2">
                          <div className="text-dark">Vanessa Tucker</div>
                          <div className="text-muted small mt-1">
                            Nam pretium turpis et arcu. Duis arcu tortor.
                          </div>
                          <div className="text-muted small mt-1">15m ago</div>
                        </div>
                      </div>
                    </a>
                    <a href="/" className="list-group-item">
                      <div className="row g-0 align-items-center">
                        <div className="col-2">
                          <img
                            src="img/avatars/avatar-2.jpg"
                            className="avatar img-fluid rounded-circle"
                            alt="William Harris"
                          />
                        </div>
                        <div className="col-10 ps-2">
                          <div className="text-dark">William Harris</div>
                          <div className="text-muted small mt-1">
                            Curabitur ligula sapien euismod vitae.
                          </div>
                          <div className="text-muted small mt-1">2h ago</div>
                        </div>
                      </div>
                    </a>
                    <a href="/" className="list-group-item">
                      <div className="row g-0 align-items-center">
                        <div className="col-2">
                          <img
                            src="img/avatars/avatar-4.jpg"
                            className="avatar img-fluid rounded-circle"
                            alt="Christina Mason"
                          />
                        </div>
                        <div className="col-10 ps-2">
                          <div className="text-dark">Christina Mason</div>
                          <div className="text-muted small mt-1">
                            Pellentesque auctor neque nec urna.
                          </div>
                          <div className="text-muted small mt-1">4h ago</div>
                        </div>
                      </div>
                    </a>
                    <a href="/" className="list-group-item">
                      <div className="row g-0 align-items-center">
                        <div className="col-2">
                          <img
                            src="img/avatars/avatar-3.jpg"
                            className="avatar img-fluid rounded-circle"
                            alt="Sharon Lessman"
                          />
                        </div>
                        <div className="col-10 ps-2">
                          <div className="text-dark">Sharon Lessman</div>
                          <div className="text-muted small mt-1">
                            Aenean tellus metus, bibendum sed, posuere ac, mattis non.
                          </div>
                          <div className="text-muted small mt-1">5h ago</div>
                        </div>
                      </div>
                    </a>
                  </div>
                  <div className="dropdown-menu-footer">
                    <a href="/" className="text-muted">
                      Show all messages
                    </a>
                  </div>
                </div>
              </li>
              <li className="nav-item dropdown">
                <a
                  className="nav-icon dropdown-toggle d-inline-block d-sm-none"
                  href="/"
                  data-bs-toggle="dropdown"
                >
                  <i className="align-middle" data-feather="settings" />
                </a>
                <a
                  className="nav-link dropdown-toggle d-none d-sm-inline-block"
                  href="/"
                  data-bs-toggle="dropdown"
                >
                  <img
                    src="img/avatars/avatar.jpg"
                    className="avatar img-fluid rounded me-1"
                    alt="Charles Hall"
                  />
                  <span className="text-dark">Charles Hall</span>
                </a>
                <div className="dropdown-menu dropdown-menu-end">
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
                </div>
              </li>
            </ul>
          </div>
        </nav>
        <main className="content">
          <div className="container-fluid p-0">
            <h1 className="h3 mb-3">
              <strong>Analytics</strong> Dashboard
            </h1>
            <div className="row">
              <div className="col-xl-6 col-xxl-5 d-flex">
                <div className="w-100">
                  <div className="row">
                    <div className="col-sm-6">
                      <div className="card">
                        <div className="card-body">
                          <div className="row">
                            <div className="col mt-0">
                              <h5 className="card-title">Sales</h5>
                            </div>
                            <div className="col-auto">
                              <div className="stat text-primary">
                                <i className="align-middle" data-feather="truck" />
                              </div>
                            </div>
                          </div>
                          <h1 className="mt-1 mb-3">2.382</h1>
                          <div className="mb-0">
                            <span className="text-danger">
                              <i className="mdi mdi-arrow-bottom-right" /> -3.65%
                            </span>
                            <span className="text-muted">Since last week</span>
                          </div>
                        </div>
                      </div>
                      <div className="card">
                        <div className="card-body">
                          <div className="row">
                            <div className="col mt-0">
                              <h5 className="card-title">Visitors</h5>
                            </div>
                            <div className="col-auto">
                              <div className="stat text-primary">
                                <i className="align-middle" data-feather="users" />
                              </div>
                            </div>
                          </div>
                          <h1 className="mt-1 mb-3">14.212</h1>
                          <div className="mb-0">
                            <span className="text-success">
                              <i className="mdi mdi-arrow-bottom-right" /> 5.25%
                            </span>
                            <span className="text-muted">Since last week</span>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div className="col-sm-6">
                      <div className="card">
                        <div className="card-body">
                          <div className="row">
                            <div className="col mt-0">
                              <h5 className="card-title">Earnings</h5>
                            </div>
                            <div className="col-auto">
                              <div className="stat text-primary">
                                <i className="align-middle" data-feather="dollar-sign" />
                              </div>
                            </div>
                          </div>
                          <h1 className="mt-1 mb-3">$21.300</h1>
                          <div className="mb-0">
                            <span className="text-success">
                              <i className="mdi mdi-arrow-bottom-right" /> 6.65%
                            </span>
                            <span className="text-muted">Since last week</span>
                          </div>
                        </div>
                      </div>
                      <div className="card">
                        <div className="card-body">
                          <div className="row">
                            <div className="col mt-0">
                              <h5 className="card-title">Orders</h5>
                            </div>
                            <div className="col-auto">
                              <div className="stat text-primary">
                                <i className="align-middle" data-feather="shopping-cart" />
                              </div>
                            </div>
                          </div>
                          <h1 className="mt-1 mb-3">64</h1>
                          <div className="mb-0">
                            <span className="text-danger">
                              <i className="mdi mdi-arrow-bottom-right" /> -2.25%
                            </span>
                            <span className="text-muted">Since last week</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div className="col-xl-6 col-xxl-7">
                <div className="card flex-fill w-100">
                  <div className="card-header">
                    <h5 className="card-title mb-0">Recent Movement</h5>
                  </div>
                  <div className="card-body py-3">
                    <div className="chart chart-sm">
                      <canvas id="chartjs-dashboard-line" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="row">
              <div className="col-12 col-md-6 col-xxl-3 d-flex order-2 order-xxl-3">
                <div className="card flex-fill w-100">
                  <div className="card-header">
                    <h5 className="card-title mb-0">Browser Usage</h5>
                  </div>
                  <div className="card-body d-flex">
                    <div className="align-self-center w-100">
                      <div className="py-3">
                        <div className="chart chart-xs">
                          <canvas id="chartjs-dashboard-pie" />
                        </div>
                      </div>
                      <table className="table mb-0">
                        <tbody>
                          <tr>
                            <td>Chrome</td>
                            <td className="text-end">4306</td>
                          </tr>
                          <tr>
                            <td>Firefox</td>
                            <td className="text-end">3801</td>
                          </tr>
                          <tr>
                            <td>IE</td>
                            <td className="text-end">1689</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </div>
              <div className="col-12 col-md-12 col-xxl-6 d-flex order-3 order-xxl-2">
                <div className="card flex-fill w-100">
                  <div className="card-header">
                    <h5 className="card-title mb-0">Real-Time</h5>
                  </div>
                  <div className="card-body px-4">
                    <div id="world_map" style={{ height: 350 }} />
                  </div>
                </div>
              </div>
              <div className="col-12 col-md-6 col-xxl-3 d-flex order-1 order-xxl-1">
                <div className="card flex-fill">
                  <div className="card-header">
                    <h5 className="card-title mb-0">Calendar</h5>
                  </div>
                  <div className="card-body d-flex">
                    <div className="align-self-center w-100">
                      <div className="chart">
                        <div id="datetimepicker-dashboard" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="row">
              <div className="col-12 col-lg-8 col-xxl-9 d-flex">
                <div className="card flex-fill">
                  <div className="card-header">
                    <h5 className="card-title mb-0">Latest Projects</h5>
                  </div>
                  <table className="table table-hover my-0">
                    <thead>
                      <tr>
                        <th>Name</th>
                        <th className="d-none d-xl-table-cell">Start Date</th>
                        <th className="d-none d-xl-table-cell">End Date</th>
                        <th>Status</th>
                        <th className="d-none d-md-table-cell">Assignee</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>Project Apollo</td>
                        <td className="d-none d-xl-table-cell">01/01/2021</td>
                        <td className="d-none d-xl-table-cell">31/06/2021</td>
                        <td>
                          <span className="badge bg-success">Done</span>
                        </td>
                        <td className="d-none d-md-table-cell">Vanessa Tucker</td>
                      </tr>
                      <tr>
                        <td>Project Fireball</td>
                        <td className="d-none d-xl-table-cell">01/01/2021</td>
                        <td className="d-none d-xl-table-cell">31/06/2021</td>
                        <td>
                          <span className="badge bg-danger">Cancelled</span>
                        </td>
                        <td className="d-none d-md-table-cell">William Harris</td>
                      </tr>
                      <tr>
                        <td>Project Hades</td>
                        <td className="d-none d-xl-table-cell">01/01/2021</td>
                        <td className="d-none d-xl-table-cell">31/06/2021</td>
                        <td>
                          <span className="badge bg-success">Done</span>
                        </td>
                        <td className="d-none d-md-table-cell">Sharon Lessman</td>
                      </tr>
                      <tr>
                        <td>Project Nitro</td>
                        <td className="d-none d-xl-table-cell">01/01/2021</td>
                        <td className="d-none d-xl-table-cell">31/06/2021</td>
                        <td>
                          <span className="badge bg-warning">In progress</span>
                        </td>
                        <td className="d-none d-md-table-cell">Vanessa Tucker</td>
                      </tr>
                      <tr>
                        <td>Project Phoenix</td>
                        <td className="d-none d-xl-table-cell">01/01/2021</td>
                        <td className="d-none d-xl-table-cell">31/06/2021</td>
                        <td>
                          <span className="badge bg-success">Done</span>
                        </td>
                        <td className="d-none d-md-table-cell">William Harris</td>
                      </tr>
                      <tr>
                        <td>Project X</td>
                        <td className="d-none d-xl-table-cell">01/01/2021</td>
                        <td className="d-none d-xl-table-cell">31/06/2021</td>
                        <td>
                          <span className="badge bg-success">Done</span>
                        </td>
                        <td className="d-none d-md-table-cell">Sharon Lessman</td>
                      </tr>
                      <tr>
                        <td>Project Romeo</td>
                        <td className="d-none d-xl-table-cell">01/01/2021</td>
                        <td className="d-none d-xl-table-cell">31/06/2021</td>
                        <td>
                          <span className="badge bg-success">Done</span>
                        </td>
                        <td className="d-none d-md-table-cell">Christina Mason</td>
                      </tr>
                      <tr>
                        <td>Project Wombat</td>
                        <td className="d-none d-xl-table-cell">01/01/2021</td>
                        <td className="d-none d-xl-table-cell">31/06/2021</td>
                        <td>
                          <span className="badge bg-warning">In progress</span>
                        </td>
                        <td className="d-none d-md-table-cell">William Harris</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
              <div className="col-12 col-lg-4 col-xxl-3 d-flex">
                <div className="card flex-fill w-100">
                  <div className="card-header">
                    <h5 className="card-title mb-0">Monthly Sales</h5>
                  </div>
                  <div className="card-body d-flex w-100">
                    <div className="align-self-center chart chart-lg">
                      <canvas id="chartjs-dashboard-bar" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
        <footer className="footer">
          <div className="container-fluid">
            <div className="row text-muted">
              <div className="col-6 text-start">
                <p className="mb-0">
                  <a
                    className="text-muted"
                    href="https://adminkit.io/"
                    target="_blank"
                    rel="noreferrer"
                  >
                    <strong>AdminKit</strong>
                  </a>
                  ©
                </p>
              </div>
              <div className="col-6 text-end">
                <ul className="list-inline">
                  <li className="list-inline-item">
                    <a
                      className="text-muted"
                      href="https://adminkit.io/"
                      target="_blank"
                      rel="noreferrer"
                    >
                      Support
                    </a>
                  </li>
                  <li className="list-inline-item">
                    <a
                      className="text-muted"
                      href="https://adminkit.io/"
                      target="_blank"
                      rel="noreferrer"
                    >
                      Help Center
                    </a>
                  </li>
                  <li className="list-inline-item">
                    <a
                      className="text-muted"
                      href="https://adminkit.io/"
                      target="_blank"
                      rel="noreferrer"
                    >
                      Privacy
                    </a>
                  </li>
                  <li className="list-inline-item">
                    <a
                      className="text-muted"
                      href="https://adminkit.io/"
                      target="_blank"
                      rel="noreferrer"
                    >
                      Terms
                    </a>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
};

export default NotFound;
