import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import moment from "moment";

import API from "../../util/apiService";

import "./notification.css";

const Notifications = () => {
  const [notificationList, setNotificationList] = useState([]);
  const { user } = useSelector((state) => state.auth);

  const fetchNotification = async () => {
    try {
      const { data } = await API.get(`/notification/api/v1/notification/${user.userName}`);
      console.log("notification", data[0]);
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
      {/* {loading && <CalyxLoader />} */}
      <h1 className="h3 mb-3">Notification List</h1>
      <div className="row">
        <div className="col-12">
          <div className="card">
            <div className="card-header">
              <div className="row">
                <div className="col-xl-12">
                  <ul className="timeline mt-2 mb-0">
                    {notificationList &&
                      notificationList.map((item) => (
                        <li className="timeline-item" key={item.createdDate}>
                          <strong>{item.messageType}</strong>
                          <span className="float-end text-muted text-sm">
                            {moment(item.createdDate).format("MM/DD/yyyy hh:mm a")}
                          </span>
                          <p>{item.message}</p>
                        </li>
                      ))}
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Notifications;
