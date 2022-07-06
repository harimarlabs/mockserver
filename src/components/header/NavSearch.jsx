import React from "react";
import { Form } from "react-bootstrap";

const NavSearch = () => {
  return (
    <Form>
      <Form.Group className="mb-3">
        <Form.Control type="text" placeholder="Search" size="sm" />
      </Form.Group>
    </Form>
  );
};

export default NavSearch;
