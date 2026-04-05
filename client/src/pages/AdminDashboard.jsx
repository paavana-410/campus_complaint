import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { API_BASE_URL } from '../api/auth';

const statusColors = {
  pending: 'secondary',
  'in-progress': 'warning',
  resolved: 'success'
};

const AdminDashboard = () => {
  const [complaints, setComplaints] = useState({
    pending: [],
    inProgress: [],
    resolved: []
  });
  const [staffList, setStaffList] = useState([]);
  const [search, setSearch] = useState('');
  const [notesEdit, setNotesEdit] = useState({});
  const [statusEdit, setStatusEdit] = useState({});
  const [activeTab, setActiveTab] = useState('pending');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const getToken = () => localStorage.getItem('token');

  useEffect(() => {
    fetchComplaints();
    fetchStaff();
  }, []);

  const fetchComplaints = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await axios.get(`${API_BASE_URL}/api/complaints`, {
        headers: {
          Authorization: `Bearer ${getToken()}`
        }
      });

      console.log('Admin complaints response:', res.data);

      setComplaints({
        pending: res.data.pending || [],
        inProgress: res.data.inProgress || [],
        resolved: res.data.resolved || []
      });
    } catch (err) {
      console.error('Complaint fetch error:', err);
      setError('Failed to fetch complaints');
    } finally {
      setLoading(false);
    }
  };

  const fetchStaff = async () => {
    try {
      const res = await axios.get(`${API_BASE_URL}/api/auth/staff`, {
        headers: {
          Authorization: `Bearer ${getToken()}`
        }
      });
      setStaffList(res.data || []);
    } catch (err) {
      console.error('Staff fetch error:', err);
      setStaffList([]);
    }
  };

  const handleAssign = async (complaintId, staffId) => {
    if (!staffId) {
      alert('Select staff to assign');
      return;
    }

    try {
      await axios.put(
        `${API_BASE_URL}/api/complaints/${complaintId}/assign`,
        { staffId },
        {
          headers: {
            Authorization: `Bearer ${getToken()}`
          }
        }
      );
      fetchComplaints();
    } catch (err) {
      console.error('Assign error:', err);
      alert(err.response?.data?.message || 'Failed to assign complaint');
    }
  };

  const handleStatusChange = (id, status) => {
    setStatusEdit((prev) => ({ ...prev, [id]: status }));
  };

  const handleNotesChange = (id, notes) => {
    setNotesEdit((prev) => ({ ...prev, [id]: notes }));
  };

  const handleStatusUpdate = async (id) => {
    try {
      await axios.put(
        `${API_BASE_URL}/api/complaints/${id}/status`,
        {
          status: statusEdit[id] || 'pending',
          resolutionNotes: notesEdit[id] || ''
        },
        {
          headers: {
            Authorization: `Bearer ${getToken()}`
          }
        }
      );
      fetchComplaints();
    } catch (err) {
      console.error('Status update error:', err);
      alert(err.response?.data?.message || 'Failed to update status');
    }
  };

  const filteredPending = complaints.pending.filter(
    (c) =>
      c.title.toLowerCase().includes(search.toLowerCase()) ||
      c.status.toLowerCase().includes(search.toLowerCase()) ||
      c.category.toLowerCase().includes(search.toLowerCase())
  );

  const filteredInProgress = complaints.inProgress.filter(
    (c) =>
      c.title.toLowerCase().includes(search.toLowerCase()) ||
      c.status.toLowerCase().includes(search.toLowerCase()) ||
      c.category.toLowerCase().includes(search.toLowerCase())
  );

  const filteredResolved = complaints.resolved.filter(
    (c) =>
      c.title.toLowerCase().includes(search.toLowerCase()) ||
      c.status.toLowerCase().includes(search.toLowerCase()) ||
      c.category.toLowerCase().includes(search.toLowerCase())
  );

  let complaintsToShow = [];
  if (activeTab === 'pending') complaintsToShow = filteredPending;
  if (activeTab === 'inProgress') complaintsToShow = filteredInProgress;
  if (activeTab === 'resolved') complaintsToShow = filteredResolved;

  return (
    <div className="container py-4">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2 className="mb-0" style={{ color: 'var(--primary-blue)' }}>
          Admin Complaint Dashboard
        </h2>

        <button className="btn btn-outline-primary" onClick={fetchComplaints}>
          <i className="fas fa-sync-alt me-1"></i>Refresh
        </button>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <input
        className="form-control mb-3"
        placeholder="Search complaints"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        style={{ maxWidth: 400 }}
      />

      <div className="mb-4 d-flex gap-3">
        <button
          className={`btn ${activeTab === 'pending' ? 'btn-primary' : 'btn-outline-primary'}`}
          onClick={() => setActiveTab('pending')}
        >
          Pending
        </button>

        <button
          className={`btn ${activeTab === 'inProgress' ? 'btn-warning' : 'btn-outline-warning'}`}
          onClick={() => setActiveTab('inProgress')}
        >
          In Progress
        </button>

        <button
          className={`btn ${activeTab === 'resolved' ? 'btn-success' : 'btn-outline-success'}`}
          onClick={() => setActiveTab('resolved')}
        >
          Resolved
        </button>
      </div>

      {loading ? (
        <div className="text-center py-4">Loading complaints...</div>
      ) : (
        <div className="table-responsive">
          <table className="table table-bordered table-hover align-middle bg-white">
            <thead className="table-light">
              <tr>
                <th>Title</th>
                <th>Status</th>
                <th>Category</th>
                <th>Due In</th>
                <th>Raised By</th>
                <th>Assigned To</th>
                <th>Assign</th>
                <th>Update Status</th>
                <th>Notes</th>
              </tr>
            </thead>

            <tbody>
              {complaintsToShow.length === 0 ? (
                <tr>
                  <td colSpan="9" className="text-center text-muted">
                    No complaints in this category
                  </td>
                </tr>
              ) : (
                complaintsToShow.map((c) => (
                  <tr key={c._id}>
                    <td>{c.title}</td>

                    <td>
                      <span className={`badge bg-${statusColors[c.status] || 'secondary'}`}>
                        {c.status}
                      </span>
                    </td>

                    <td>{c.category}</td>

                    <td>{c.dueInDays}</td>

                    <td>{c.raisedBy?.email || '-'}</td>

                    <td>{c.assignedTo?.email || 'Unassigned'}</td>

                    <td>
                      <select
                        className="form-select"
                        value={c.assignedTo?._id || ''}
                        onChange={(e) => handleAssign(c._id, e.target.value)}
                      >
                        <option value="">Assign staff</option>
                        {staffList.map((staff) => (
                          <option key={staff._id} value={staff._id}>
                            {staff.name || staff.email}
                            {staff.department ? ` (${staff.department})` : ''}
                          </option>
                        ))}
                      </select>
                    </td>

                    <td>
                      <select
                        className="form-select"
                        value={statusEdit[c._id] || c.status}
                        onChange={(e) => handleStatusChange(c._id, e.target.value)}
                      >
                        <option value="pending">Pending</option>
                        <option value="in-progress">In Progress</option>
                        <option value="resolved">Resolved</option>
                      </select>

                      <button
                        className="btn btn-sm btn-primary mt-2"
                        onClick={() => handleStatusUpdate(c._id)}
                      >
                        Update
                      </button>
                    </td>

                    <td>
                      <input
                        className="form-control"
                        placeholder="Notes"
                        value={
                          notesEdit[c._id] !== undefined
                            ? notesEdit[c._id]
                            : c.resolutionNotes || ''
                        }
                        onChange={(e) => handleNotesChange(c._id, e.target.value)}
                      />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default AdminDashboard;
