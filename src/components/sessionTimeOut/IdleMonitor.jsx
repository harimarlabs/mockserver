import React, { useState, useEffect } from "react";
// import { Modal, ModalHeader, ModalBody, ModalFooter } from "reactstrap";

import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { addEventListeners, removeEventListeners } from "../../util/eventListenerUtil";

import { logoutUser } from "../../store/actions/auth";

export const TIMEOUTS = {
  IDLE_TIMEOUT: 60 * 1000, // 60sec
  LOGOUT_POPUP: 10 * 1000,
  ONE_SEC: 1000,
};

const IdleMonitor = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const [time, setTime] = useState(TIMEOUTS.LOGOUT_POPUP / TIMEOUTS.ONE_SEC);

  const logOut = () => {
    console.log("logging out");
    // dispatch(logoutUser(navigate));
  };

  const extendSession = () => {
    console.log("user wants to stay logged in");
  };

  const handleClick = () => {
    console.log("close the modal");
  };

  // Modal
  const [idleModal, setIdleModal] = useState(false);

  //   const idleTimeout = 1000 * 60 * 1; // 1 minute
  const idleTimeout = 1000 * 5; // 1 minute
  //   const idleLogout = 1000 * 60 * 2; // 2 Minutes
  const idleLogout = 1000 * 10; // 2 Minutes
  let idleEvent;
  let idleLogoutEvent;

  /**
   * Add any other events listeners here
   */
  //   const events = ["mousemove", "click", "keypress"];
  const eventTypes = [
    "keypress",
    "click",
    "mousemove",
    "mousedown",
    "scroll",
    "touchmove",
    "pointermove",
  ];

  /**
   * @method sessionTimeout
   * This function is called with each event listener to set a timeout or clear a timeout.
   */
  const sessionTimeout = () => {
    if (idleEvent) clearTimeout(idleEvent);
    if (idleLogoutEvent) clearTimeout(idleLogoutEvent);

    idleEvent = setTimeout(() => setIdleModal(true), idleTimeout); // show session warning modal.
    idleLogoutEvent = setTimeout(() => logOut, idleLogout); // Call logged out on session expire.
  };

  //   const listener = () => {
  //     if (!isWarningModalOpen) {
  //       clearTimeout(timeout);
  //       timeout = createTimeout1();
  //     }
  //   };

  useEffect(() => {
    // eventTypes.forEach((type) => {
    //   window.addEventListener(type, sessionTimeout, false);
    // });

    eventTypes.forEach((type) => {
      window.addEventListener(type, sessionTimeout);
    });

    if (idleModal) {
      window.setTimeout(() => setTime(time - 1), TIMEOUTS.ONE_SEC);
    }

    // for (const e in events) {
    //   window.addEventListener(events[e], sessionTimeout);
    // }
    return () => {
      //   for (const e in events) {
      //     window.removeEventListener(events[e], sessionTimeout);
      //   }
      //   eventTypes.forEach((type) => {
      //     window.removeEventListener(type, sessionTimeout, false);
      //   });

      eventTypes.forEach((type) => {
        window.removeEventListener(type, sessionTimeout);
      });
    };
  }, []);

  return (
    <>
      <Modal show={idleModal} onHide={() => setIdleModal(!idleModal)} size="sm" centered>
        <Modal.Body>
          <div> your session will expire in {time} minutes. Do you want to extend the session?</div>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="primary" onClick={logOut}>
            Logout
          </Button>
          <Button variant="primary" onClick={extendSession}>
            Keep Logged In
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
};

export default IdleMonitor;
