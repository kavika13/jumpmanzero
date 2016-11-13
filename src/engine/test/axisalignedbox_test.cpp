#define GLM_FORCE_LEFT_HANDED
#include <glm/gtx/io.hpp>
#include "engine/axisalignedbox.hpp"
#include "catch.hpp"

using AxisAlignedBox = Jumpman::AxisAlignedBox;

SCENARIO ("create axis aligned box from extents",
          "[geometry]") {
  GIVEN ("two positive coordinates") {
    const auto min = glm::vec3(2.0f);
    const auto max = glm::vec3(5.0f);

    WHEN ("the box is created") {
      const auto box = AxisAlignedBox::FromExtents(min, max);

      THEN ("correct min and max values") {
        REQUIRE (box.min == min);
        REQUIRE (box.max == max);
      }
    }
  }

  GIVEN ("two negative coordinates") {
    const auto min = glm::vec3(-5.0f);
    const auto max = glm::vec3(-2.0f);

    WHEN ("the box is created") {
      const auto box = AxisAlignedBox::FromExtents(min, max);

      THEN ("correct min and max values") {
        REQUIRE (box.min == min);
        REQUIRE (box.max == max);
      }
    }
  }
}

SCENARIO ("create axis aligned box from origin and half-dimensions",
          "[geometry]") {
  GIVEN ("positive origin and half-dimensions") {
    const auto origin = glm::vec3(7.0f);
    const auto half_dimensions = glm::vec3(5.0f);

    WHEN ("the box is created") {
      const auto box = AxisAlignedBox::FromOrigin(origin, half_dimensions);

      THEN ("correct min and max values") {
        REQUIRE (box.min == glm::vec3(2.0f));
        REQUIRE (box.max == glm::vec3(12.0f));
      }
    }
  }

  GIVEN ("negative origin and positive half-dimensions") {
    const auto origin = glm::vec3(-7.0f);
    const auto half_dimensions = glm::vec3(5.0f);

    WHEN ("the box is created") {
      const auto box = AxisAlignedBox::FromOrigin(origin, half_dimensions);

      THEN ("correct min and max values") {
        REQUIRE (box.min == glm::vec3(-12.0f));
        REQUIRE (box.max == glm::vec3(-2.0f));
      }
    }
  }
}

SCENARIO ("create axis aligned box from points",
          "[geometry]") {
  GIVEN ("positive points") {
    const std::vector<glm::vec3> points {
      glm::vec3(7.0f),
      glm::vec3(5.0f),
      glm::vec3(19.0f),
      glm::vec3(3.0f),
    };

    WHEN ("the box is created") {
      const auto box = AxisAlignedBox::FromPoints(points);

      THEN ("correct min and max values") {
        REQUIRE (box.min == glm::vec3(3.0f));
        REQUIRE (box.max == glm::vec3(19.0f));
      }
    }
  }

  GIVEN ("negative points") {
    const std::vector<glm::vec3> points {
      glm::vec3(-7.0f),
      glm::vec3(-5.0f),
      glm::vec3(-19.0f),
      glm::vec3(-3.0f),
    };

    WHEN ("the box is created") {
      const auto box = AxisAlignedBox::FromPoints(points);

      THEN ("correct min and max values") {
        REQUIRE (box.min == glm::vec3(-19.0f));
        REQUIRE (box.max == glm::vec3(-3.0f));
      }
    }
  }
}

SCENARIO ("create axis aligned box from vector of vec3 points",
          "[geometry]") {
  GIVEN ("positive points") {
    const std::vector<glm::vec3> points {
      glm::vec3(7.0f, 7.0f, 2.0f),
      glm::vec3(1.0f, 5.0f, 5.0f),
      glm::vec3(19.0f, 19.0f, 19.0f),
      glm::vec3(3.0f, 20.0f, 3.0f),
    };

    WHEN ("the box is created") {
      const auto box = AxisAlignedBox::FromPoints(points);

      THEN ("correct min and max values") {
        REQUIRE (box.min == glm::vec3(1.0f, 5.0f, 2.0f));
        REQUIRE (box.max == glm::vec3(19.0f, 20.0f, 19.0f));
      }
    }
  }

  GIVEN ("negative points") {
    const std::vector<glm::vec3> points {
      glm::vec3(-7.0f, -7.0f, -2.0f),
      glm::vec3(-1.0f, -5.0f, -5.0f),
      glm::vec3(-19.0f, -19.0f, -19.0f),
      glm::vec3(-3.0f, -20.0f, -3.0f),
    };

    WHEN ("the box is created") {
      const auto box = AxisAlignedBox::FromPoints(points);

      THEN ("correct min and max values") {
        REQUIRE (box.min == glm::vec3(-19.0f, -20.0f, -19.0f));
        REQUIRE (box.max == glm::vec3(-1.0f, -5.0f, -2.0f));
      }
    }
  }
}

SCENARIO ("get origin of axis aligned box",
          "[geometry]") {
  GIVEN ("a box with two positive coordinates") {
    const auto box = AxisAlignedBox::FromExtents(
      glm::vec3(5.0f), glm::vec3(8.0f));

    WHEN ("the origin is retrieved") {
      const glm::vec3 origin = box.GetOrigin();

      THEN ("correct value is returned") {
        REQUIRE (origin == glm::vec3(6.5f));
      }
    }
  }

  GIVEN ("a box with two negative coordinates") {
    const auto box = AxisAlignedBox::FromExtents(
      glm::vec3(-18.0f), glm::vec3(-7.0f));

    WHEN ("the origin is retrieved") {
      const glm::vec3 origin = box.GetOrigin();

      THEN ("correct value is returned") {
        REQUIRE (origin == glm::vec3(-12.5f));
      }
    }
  }
}

// TODO: Test SetOrigin
// TODO: Test GetHalfDimensions
// TODO: Test SetHalfDimensions
// TODO: Test GetDimensions
// TODO: Test SetDimensions

SCENARIO ("get volume of axis aligned box",
          "[geometry]") {
  GIVEN ("a box with two positive coordinates") {
    const auto box = AxisAlignedBox::FromExtents(
      glm::vec3(5.0f), glm::vec3(7.0f, 9.0f, 12.0f));

    WHEN ("the volume is retrieved") {
      const float volume = box.GetVolume();

      THEN ("correct value is returned") {
        REQUIRE (volume == 2 * 4 * 7);
      }
    }
  }

  GIVEN ("a box with two negative coordinates") {
    const auto box = AxisAlignedBox::FromExtents(
      glm::vec3(-18.0f), glm::vec3(-15.0f, -12.0f, -7.0f));

    WHEN ("the volume is retrieved") {
      const float volume = box.GetVolume();

      THEN ("correct value is returned") {
        REQUIRE (volume == 3 * 6 * 11);
      }
    }
  }

  GIVEN ("a box both positive and negative coordinates") {
    const auto box = AxisAlignedBox::FromExtents(
      glm::vec3(-18.0f), glm::vec3(1.0f, -3.0f, 7.0f));

    WHEN ("the volume is retrieved") {
      const float volume = box.GetVolume();

      THEN ("correct value is returned") {
        REQUIRE (volume == 19 * 15 * 25);
      }
    }
  }
}

// TODO: Test IsIntersecting(const AxisAlignedBox& other) const noexcept;
// TODO: Test IsIntersectingXY(const AxisAlignedBox& other) const noexcept;
// TODO: Test Contains(const glm::vec3& point) const noexcept;
// TODO: Test Contains(const AxisAlignedBox& other) const noexcept;
// TODO: Test ContainsXY(const glm::vec3& point) const noexcept;
// TODO: Test ContainsXY(const AxisAlignedBox& other) const noexcept;
// TODO: Test GetOverlap
