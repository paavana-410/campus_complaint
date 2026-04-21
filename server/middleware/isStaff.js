const isStaff = (req, res, next) => {
    if (req.user?.role === 'staff') {
        next();
    } else {
        res.status(403).json({ message: 'Staff only.' });
    }
};

module.exports = isStaff; 