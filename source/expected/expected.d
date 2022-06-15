/**
* a template error type, compatible with @safe and @nogc.
*
* Authors: Susan
* Date: 2021-12-10
* Licence: AGPL-3.0 or later
* Copyright: Hybrid Development Team, 2021
*/
module expected;

///
alias Expected(FailureType) = Expected!(void, FailureType);

/// tagged union containing result or error. indicates failure by default
struct Expected(ResultType, FailureType)
if(is(FailureType == enum))
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
		FailureType failure;
		static if(!is(ResultType == void))
		{
			ResultType result;
		}
	}

	static if(!is(ResultType == void))
	{
		///
		this(ResultType rhs) const
		{
			_tag = Tag.Success;
			contents.result = rhs;
		}
	}

	/// ditto
	this(in FailureType rhs) const
	{
		_tag = Tag.Failure;
		contents.failure = rhs;
	}

	static if(!is(ResultType == bool))
	{
		///ditto
		this(in bool successful) const
		{
			if(successful)
			{
				_tag = Tag.Success;
				static if(!is(ResultType == void))
				{
					contents.result = ResultType.init;
				}
			}
			else
			{
				_tag = Tag.Failure;
				contents.failure = FailureType.init;
			}
		}
	}

	/// tag state.
	@property Tag tag() const @nogc nothrow pure @safe
	{
		return _tag;
	}

	static if(!is(ResultType == void))
	{
		/// result //trusted because tagged unions aren't builtin
		@property inout(ResultType) result() inout @trusted
		in (tag == Tag.Success)
		{
			return contents.result;
		}

		/// ditto
		@property void result(ResultType result) @trusted
		out (; tag == Tag.Success)
		{
			_tag = Tag.Success;
			contents.result = result;
		}
	}

	/// failure mode
	@property FailureType failure() const @trusted
	in (tag == Tag.Failure)
	{
		return contents.failure;
	}

	/// ditto
	@property void failure(in FailureType failure) @trusted
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
		void test() const @nogc nothrow pure @safe
		{
			//to ensure the invariant is run
		}
	}

	auto bar = Expected!(S, Failure)(true);
	assert(bar.tag == bar.Tag.Success);
	assert(bar.result == S.init);

	bar.result = S(5);
	bar.result.test();
	assert(bar.tag == bar.Tag.Success);
	assert(bar.result.field == 5);

	bar.failure = Failure.Error2;
	assert(bar.tag == bar.Tag.Failure);

	immutable Expected!(S, Failure) baz = Failure.Error1;
	assert(baz.failure == Failure.Error1);

	//and with classes!
	class C
	{
		S field;
	}

	scope c = new C;
	c.field = S(420);
	Expected!(C, Failure) sus;
	sus.result = c;
	assert(sus.result.field == S(420));

	immutable voidUser = Expected!(Failure)(true);
	assert(voidUser.tag == voidUser.Tag.Success);

	immutable voidUser2 = Expected!(Failure)(false);
	assert(voidUser2.tag == voidUser.Tag.Failure);
}
