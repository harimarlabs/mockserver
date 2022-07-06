import React, { useEffect, useState } from "react";

import { addEventListeners, removeEventListeners } from "../../util/eventListenerUtil";
import TimeoutWarningModal from "./TimeoutWarningModal";

const SessionTimeout = () => {
  const [isWarningModalOpen, setWarningModalOpen] = useState(false);
  let timeout = null;
  useEffect(() => {
    const createTimeout1 = () =>
      setTimeout(() => {
        setWarningModalOpen(true);
      }, 5000);

    const createTimeout2 = () =>
      setTimeout(() => {
        // Implement a sign out function here
        // window.location.href = "https://vincentntang.com";
        console.log("redirect to logout");
      }, 10000);

    const listener = () => {
      if (!isWarningModalOpen) {
        clearTimeout(timeout);
        timeout = createTimeout1();
      }
    };

    // Initialization
    timeout = isWarningModalOpen ? createTimeout2() : createTimeout1();
    addEventListeners(listener);

    // Cleanup
    return () => {
      removeEventListeners(listener);
      clearTimeout(timeout);
    };
  }, [isWarningModalOpen]);
  return (
    <div>
      {isWarningModalOpen && (
        <TimeoutWarningModal
          isOpen={isWarningModalOpen}
          handleClick={() => setWarningModalOpen(!isWarningModalOpen)}
        />
      )}
    </div>
  );
};

export default SessionTimeout;
