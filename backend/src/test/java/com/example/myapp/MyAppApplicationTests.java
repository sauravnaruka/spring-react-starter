package com.example.myapp;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@Disabled("Requires a running database — enable once DB is configured")
@SpringBootTest
class MyAppApplicationTests {

	@Test
	void contextLoads() {
	}

}
