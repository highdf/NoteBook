package com.luky;

import java.util.function.Consumer;
import java.util.stream.Stream;

/**
 * Hello world!
 *
 */
public class App 
{
	public static void main( String[] args )
	{
		Stream.of(
			"Bob", "Alice", "Xin", "George", "Ken"
		).filter(s -> s.equals("Bob"))
		 .forEach();
	}
}
