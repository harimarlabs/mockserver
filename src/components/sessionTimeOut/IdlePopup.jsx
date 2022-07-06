/// IdlePopup.tsx

import { useEffect, useRef, useState } from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";

export const TIMEOUTS = {
  IDLE_TIMEOUT: 60 * 1000, // 60sec
  LOGOUT_POPUP: 10 * 1000,
  ONE_SEC: 1000,
};

const IdlePopup = ({ show, onClose }) => {
  const [time, setTime] = useState(TIMEOUTS.LOGOUT_POPUP / TIMEOUTS.ONE_SEC);
  const mounted = useRef(0);

  //   useEffect(() => {
  //     if (show) {
  //       if (time <= 1) {
  //         mounted.current && window.clearTimeout(mounted.current);
  //         onClose(true);
  //         return;
  //       }
  //       mounted.current = window.setTimeout(() => setTime(time - 1), TIMEOUTS.ONE_SEC);
  //     } else {
  //       setTime(TIMEOUTS.LOGOUT_POPUP / TIMEOUTS.ONE_SEC);
  //     }

  //     return () => {
  //       mounted.current && window.clearTimeout(mounted.current);
  //     };
  //   }, [show, time]);

  useEffect(() => {
    if (show) {
      if (time <= 1) {
        if (mounted.current) {
          window.clearTimeout(mounted.current);
        }
        onClose(true);
        return;
      }
      mounted.current = window.setTimeout(() => setTime(time - 1), TIMEOUTS.ONE_SEC);
    } else {
      setTime(TIMEOUTS.LOGOUT_POPUP / TIMEOUTS.ONE_SEC);
    }
    // return () => {
    //   if (mounted.current) {
    //     window.clearTimeout(mounted.current);
    //   }
    // };
  }, [show, time]);

  return (
    <>
      <Modal show={show} onHide={() => onClose(false)} size="sm" centered>
        <Modal.Body>
          <div>
            {" "}
            your session will expire in {time}=== minutes. Do you want to extend the session?
          </div>
        </Modal.Body>

        <Modal.Footer>
          {/* <button type="button" className="btn btn-info" onClick={() => logOut()}>
            Logout
          </button>
          <button type="button" className="btn btn-success" onClick={() => extendSession()}>
            Extend session
          </button> */}
          <Button variant="primary" onClick={() => onClose(true)}>
            Logout
          </Button>
          <Button variant="primary" onClick={() => onClose(false)}>
            Keep Logged In
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
};
export default IdlePopup;
