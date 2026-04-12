import React, { useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "./firebase";

const Users = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchUsers = async () => {
            try {   
                const usersRef = collection(db, "users");
                const querySnapshot = await getDocs(usersRef);
                const usersList = [];
                querySnapshot.forEach((doc) => {
                    usersList.push(doc.data());
                });
                setUsers(usersList);
            } catch (err) {
                setError("Failed to fetch users.");
                console.error("Error fetching users:", err);
            } finally {
                setLoading(false);
            }
        };

        fetchUsers();
    }, []);

    if (loading) return <p>Loading users...</p>;
    if (error) return <p>{error}</p>;
    return (
        <div>
            <h1>Users</h1>  
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Banned</th>
                    </tr>
                </thead>
                <tbody>
                    {users.map((user, index) => (
                        <tr key={index}>
                            <td>{user.displayName || `${user.firstName || ""} ${user.lastName || ""}`.trim()}</td>
                            <td>{user.email}</td>
                            <td>{user.isBanned ? "Yes" : "No"}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
};

export default Users;