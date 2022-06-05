/**
* a template error type, compatible with @safe and @nogc.
*
* Authors: Susan
* Date: 2021-12-10
* Licence: AGPL-3.0 or later
* Copyright: Hybrid Development Team, 2021
*/
module expected;

/// tagged union containing result or error. indicates failure by default
struct Expected(ResultType, FailureModeType)
{
    /// tag enum.
    enum Tag
    {
        Success,
        Failure
    }

    private Tag _tag = Tag.Failure;
    private ResultAndFailureMode!(ResultType, FailureModeType) contents;

	/// constructor
	this(in ResultType rhs) const @nogc nothrow pure @safe
	{
		_tag = Tag.Success;
		contents.result = rhs;
	}

	/// ditto
	this(in FailureModeType rhs) const @nogc nothrow pure @safe
	{
		_tag = Tag.Failure;
		contents.failureMode = rhs;
	}

    /// tag state. readonly
    @property Tag tag() const @nogc nothrow pure @safe
    {
        return _tag;
    }

    /// result //trusted because tagged unions aren't builtin
    @property const(ResultType) result() const @nogc nothrow pure @trusted
    in (tag == Tag.Success)
    {
        return contents.result;
    }

    /// ditto
    @property void result(ResultType result) @nogc nothrow pure @trusted
    out (; tag == Tag.Success)
    {
        _tag = Tag.Success;
        contents.result = result;
    }

    /// failure mode
    @property FailureModeType failureMode() const @nogc nothrow pure @trusted
    in (tag == Tag.Failure)
    {
        return contents.failureMode;
    }

    /// ditto
    @property void failureMode(in FailureModeType failureMode) @nogc nothrow pure @trusted
    out (; tag == Tag.Failure)
    {
        _tag = Tag.Failure;
        contents.failureMode = failureMode;
    }
}

private union ResultAndFailureMode(ResultType, FailureModeType)
{
    ResultType result;
    FailureModeType failureMode;
}

@nogc nothrow pure @safe unittest
{
    enum FailureMode
    {
        Error1,
        Error2
    }

    Expected!(int, FailureMode) foo = 5;
	assert(foo.tag == foo.Tag.Success);
	assert(foo.result == 5);

    foo.failureMode = FailureMode.Error2;
	assert(foo.tag == foo.Tag.Failure);
	assert(foo.failureMode == FailureMode.Error2);

	struct S
	{
		invariant(field != 69);
		int field;
	}

	Expected!(S, FailureMode) bar;
	bar.result = S(5); //workaround for property shenanigans
	assert(bar.tag == bar.Tag.Success);
	assert(bar.result.field == 5);

    bar.failureMode = FailureMode.Error2;
	assert(bar.tag == bar.Tag.Failure);

	Expected!(S, FailureMode) baz = FailureMode.Error1;
	assert(baz.failureMode == FailureMode.Error1);
}
