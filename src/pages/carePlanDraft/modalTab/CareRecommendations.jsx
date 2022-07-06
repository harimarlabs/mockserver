import React from "react";

const CareRecommendations = ({ register, viewData }) => {
  return (
    <div className="row mt-4">
      <div className="col-md-6">
        <div className="card card-info">
          <div className="card-header p-2">
            <h3 className="card-title text-bold">Discharge Recommendations</h3>
          </div>
          <div className="card-body info-val p-2">
            {viewData?.recommendation ? viewData?.recommendation : "-"}
          </div>
        </div>
      </div>
      <div className="col-md-6">
        <div className="card card-info">
          <div className="card-header p-2">
            <h3 className="card-title text-bold">Other Recommendations</h3>
          </div>
          <div className="card-body">
            <textarea
              rows="3"
              className="w-100 info-val"
              name="otherRecommendation"
              {...register("otherRecommendation")}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default CareRecommendations;
