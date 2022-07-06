import { React, useEffect, useState } from "react";
import API from "../../util/apiService";

const Users = () => {
  const [userList, setUserList] = useState([]);

  const fetchData = async () => {
    try {
      const { data } = await API.get("/authentication/api/v1.0/users/");
      setUserList(data);
      // console.log(data);
    } catch (error) {
      console.log(error);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  return (
    <div className="card-body p-0">
      <div className="row">
        <div className="col 12">
          <table className="table text-black-100">
            <thead>
              <tr>
                <th scope="col">FirstName</th>
                <th scope="col">LastName</th>
                <th scope="col">LoginId</th>
                <th scope="col">RoleName</th>
              </tr>
            </thead>
            <tbody>
              {userList.map((item) => (
                <tr key={item.id}>
                  <td>{item.firstName ? item.firstName : "-"}</td>
                  <td>{item.lastName ? item.lastName : "-"}</td>
                  <td>{item.loginId ? item.loginId : "-"}</td>
                  <td>{item.role.name ? item.role.name : "-"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Users;
