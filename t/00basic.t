print "1..1\n";

eval {
    require StateMachine::Gestinanna;
};

if($@) {
    print "not ok 1\n";
} else {
    print "ok 1\n";
}

exit 0;
