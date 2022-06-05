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
struct Expected(ResultType, FailureType)
{
	/// tag enum.
	enum Tag
	{
		Success,
		Failure
	}

	private Tag _tag = Tag.Failure;
	private ResultAndFailure contents;

	private union ResultAndFailure
	{
		ResultType result;
		FailureType failure;
	}

	/// constructor
	this(in ResultType rhs) const @nogc nothrow pure @safe
	{
		_tag = Tag.Success;
		contents.result = rhs;
	}

	/// ditto
	this(in FailureType rhs) const @nogc nothrow pure @safe
	{
		_tag = Tag.Failure;
		contents.failure = rhs;
	}

	/// tag state.
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
	@property FailureType failure() const @nogc nothrow pure @trusted
	in (tag == Tag.Failure)
	{
		return contents.failure;
	}

	/// ditto
	@property void failure(in FailureType failure) @nogc nothrow pure @trusted
	out (; tag == Tag.Failure)
	{
		_tag = Tag.Failure;
		contents.failure = failure;
	}
}

///
@nogc nothrow pure @safe unittest
{
	enum Failure
	{
		Error1,
		Error2
	}

	Expected!(int, Failure) foo = 5;
	assert(foo.tag == foo.Tag.Success);
	assert(foo.result == 5);

	foo.failure = Failure.Error2;
	assert(foo.tag == foo.Tag.Failure);
	assert(foo.failure == Failure.Error2);

	struct S
	{
		invariant(field != 69);
		int field;
	}

	Expected!(S, Failure) bar;
	bar.result = S(5); //workaround for property shenanigans
	assert(bar.tag == bar.Tag.Success);
	assert(bar.result.field == 5);

	bar.failure = Failure.Error2;
	assert(bar.tag == bar.Tag.Failure);

	immutable Expected!(S, Failure) baz = Failure.Error1;
	assert(baz.failure == Failure.Error1);
}
