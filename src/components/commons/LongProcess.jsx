import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";

import API from "../../util/apiService";

const LongProcess = ({ docid }) => {
  const [progress, setProgress] = useState("0%");
  const [isComplete, setComplete] = useState(false);
  const [step, setStep] = useState(10);
  const navigate = useNavigate();

  const statusChecking = async () => {
    if (!isComplete && docid !== 0) {
      try {
        const res = await API.get(`/inboundintegration/api/v1.0/itedocument/extract/${docid}`);
        console.log("data====+++", res);

        if (res.data === "SUCCESS") {
          setProgress("100%");
          setComplete(true);
          // navigate("/patient-enrollment");
          // Consider calling navigate("/patient-enrollment");
        } else {
          setProgress(`${step}%`);
          setTimeout(() => {
            setStep(step + 10);
          }, 2000);
        }

        if (res.status !== 200) {
          console.log("alert or redirect here");
        }

        if (res.status === 500) {
          console.log("error in response", res);
        }

        console.log("res 7777", res);

        // toast.success("User Login Successfully");
      } catch (error) {
        // toast.error(`${error.response.data}`);
        console.error("error", error);

        // if (error.response) {
        //   // The client was given an erroror response (5xx, 4xx)
        // } else if (error.request) {
        //   // The client never received a response, and the request was never left
        // } else {
        //   // Anything else
        // }
      }
    }
  };

  useEffect(() => {
    statusChecking();
  }, [docid, isComplete, step]);

  // useEffect(() => {
  //   if (!isComplete && docid !== 0) {
  //     try {
  //       API.get(`/riskevaluation/api/v1.0/itedocument/extract/${docid}`, {}).then((resp) => {
  //         if (resp.data === "SUCCESS") {
  //           setProgress("100%");
  //           setComplete(true);
  //           navigate("/patient-enrollment");
  //           // Consider calling navigate("/patient-enrollment");
  //         } else {
  //           setProgress(`${step}%`);
  //           setTimeout(() => {
  //             setStep(step + 10);
  //           }, 2000);
  //         }

  //         if (resp.status === 500) {
  //           console.log("error=======", resp);
  //         }
  //       });
  //     } catch (error) {
  //       console.log("error", error);
  //       navigate("/patient-enrollment");

  //       // toast.error(`${error.response.data?.error}`);
  //     }
  //   }
  // }, [docid, isComplete, step]);

  return (
    <div className="container">
      <div className="progress" style={{ height: 20 }}>
        <div className="progress-bar" style={{ width: progress }} />
      </div>
      {docid !== 0 && <div>Extracting information from the discharge summary</div>}
      {isComplete && <div>Done.</div>}
    </div>
  );
};

export default LongProcess;
