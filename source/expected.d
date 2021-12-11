module expected;

/**
* a @safe, @nogc-compatible template error type.
*
* you should probably use out parameters instead of this.
*
* Authors: Susan
* Date: 2021-12-10
* Licence: AGPL-3.0 or later
* Copyright: Hybrid Development Team, 2021
*/

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
	this(in ResultType rhs) @safe @nogc nothrow const pure
	{
		_tag = Tag.Success;
		contents.result = rhs;
	}

	///ditto
	this(in FailureModeType rhs) @safe @nogc nothrow const pure
	{
		_tag = Tag.Failure;
		contents.failureMode = rhs;
	}

    /// tag state. readonly
    @property Tag tag() @safe @nogc nothrow const pure
    {
        return _tag;
    }

    ///result property //trusted because tagged unions aren't builtin
    @property const(ResultType) result() @trusted @nogc nothrow const pure
    in (tag == Tag.Success)
    {
        return contents.result;
    }

    ///ditto
    @property void result(ResultType result) @trusted @nogc nothrow pure
    out (; tag == Tag.Success)
    {
        _tag = Tag.Success;
        contents.result = result;
    }

    ///failure mode property
    @property FailureModeType failureMode() @safe @nogc nothrow const pure
    in (tag == Tag.Failure)
    {
        return contents.failureMode;
    }

    ///ditto
    @property void failureMode(in FailureModeType failureMode) @safe @nogc nothrow pure
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

@safe @nogc nothrow pure unittest
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
